"""
AudioOutput — Windows physical speaker playback via sounddevice.

Accepts WAV bytes produced by the TTS backend and plays the decoded PCM
directly on the selected Windows output device.

All diagnostics go to stderr so stdout remains clean for IPC.
"""

import io
import sys
import wave
import threading
from typing import Optional, Dict, Any, List

import numpy as np
import sounddevice as sd


def _log(message: str):
    """Write diagnostics to stderr only."""
    print(message, file=sys.stderr, flush=True)


class AudioOutput:
    """
    Windows audio playback using sounddevice.

    The TTS backend returns a normal RIFF/WAVE PCM16 file. We decode that
    container ourselves and send the PCM samples directly to the selected
    device using RawOutputStream.

    Important:
      - The WAV sample rate is used exactly as encoded.
      - No device-rate conversion is performed here.
      - The selected output device is explicit when supplied.
      - Audio is converted to contiguous float32 before playback.
    """

    def __init__(
        self,
        sample_rate: int = 44100,
        channels: int = 1,
        device_id: Optional[int] = None,
    ):
        self.default_sample_rate = int(sample_rate)
        self.default_channels = int(channels)
        self.selected_device_id = device_id
        self._lock = threading.Lock()

    # ------------------------------------------------------------------
    # Device enumeration
    # ------------------------------------------------------------------

    def list_output_devices(self) -> List[Dict[str, Any]]:
        devices: List[Dict[str, Any]] = []

        try:
            default_out = sd.default.device[1]
        except Exception:
            default_out = None

        try:
            all_devices = sd.query_devices()
        except Exception as e:
            _log(f"[AudioOutput ERROR] Device query failed: {e}")
            return devices

        for idx, dev in enumerate(all_devices):
            if dev.get("max_output_channels", 0) > 0:
                devices.append(
                    {
                        "id": idx,
                        "name": dev.get("name"),
                        "channels": int(dev.get("max_output_channels", 0)),
                        "default_sample_rate": int(
                            dev.get("default_samplerate", 44100)
                        ),
                        "is_default": idx == default_out,
                    }
                )

        return devices

    def print_output_devices(self):
        devices = self.list_output_devices()

        _log("\n[AudioOutput] Available output devices:")
        _log(f"  {'ID':>3}  {'Default':>7}  {'SR':>6}  {'Ch':>2}  Name")
        _log(f"  {'-' * 3}  {'-' * 7}  {'-' * 6}  {'-' * 2}  {'-' * 40}")

        for d in devices:
            marker = " <--" if d["is_default"] else ""

            _log(
                f"  {d['id']:>3}  "
                f"{'YES' if d['is_default'] else '':>7}  "
                f"{d['default_sample_rate']:>6}  "
                f"{d['channels']:>2}  "
                f"{d['name']}{marker}"
            )

    def select_output_device(self, device_id: Optional[int] = None):
        self.selected_device_id = device_id

        if device_id is None:
            _log("[AudioOutput] Output device: system default")
            return

        try:
            info = sd.query_devices(device_id)
            _log(
                f"[AudioOutput] Selected output device: "
                f"[{device_id}] {info.get('name')}"
            )
        except Exception as e:
            _log(
                f"[AudioOutput] Selected output device ID {device_id} "
                f"(query failed: {e})"
            )

    # ------------------------------------------------------------------
    # WAV decoding
    # ------------------------------------------------------------------

    @staticmethod
    def _decode_wav(
        audio_data: bytes,
    ) -> tuple[np.ndarray, int, int]:
        """
        Decode PCM WAV bytes.

        Returns:
            audio_float32, sample_rate, channels
        """

        if len(audio_data) < 12:
            raise ValueError("Audio data is shorter than a WAV header.")

        if audio_data[:4] != b"RIFF" or audio_data[8:12] != b"WAVE":
            raise ValueError("Expected RIFF/WAVE audio bytes.")

        wav_io = io.BytesIO(audio_data)

        with wave.open(wav_io, "rb") as wf:
            channels = wf.getnchannels()
            sample_width = wf.getsampwidth()
            sample_rate = wf.getframerate()
            frame_count = wf.getnframes()
            raw_pcm = wf.readframes(frame_count)

        if channels <= 0:
            raise ValueError(f"Invalid channel count: {channels}")

        if sample_rate <= 0:
            raise ValueError(f"Invalid sample rate: {sample_rate}")

        if sample_width == 2:
            audio = (
                np.frombuffer(raw_pcm, dtype="<i2")
                .astype(np.float32)
                / 32768.0
            )

        elif sample_width == 4:
            audio = (
                np.frombuffer(raw_pcm, dtype="<i4")
                .astype(np.float32)
                / 2147483648.0
            )

        else:
            raise ValueError(
                f"Unsupported PCM sample width: {sample_width} bytes"
            )

        expected_values = frame_count * channels

        if audio.size != expected_values:
            raise ValueError(
                f"Invalid PCM data size: got {audio.size}, "
                f"expected {expected_values}"
            )

        if channels > 1:
            audio = audio.reshape(frame_count, channels)

        # sounddevice expects a contiguous numeric array.
        audio = np.ascontiguousarray(audio, dtype=np.float32)

        if not np.all(np.isfinite(audio)):
            raise ValueError("Decoded audio contains NaN/Inf.")

        return audio, int(sample_rate), int(channels)

    # ------------------------------------------------------------------
    # Playback
    # ------------------------------------------------------------------

    def play(
        self,
        audio_data: bytes,
        sample_rate: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Play WAV bytes through the selected Windows output device.

        For WAV input, the WAV's own sample rate is authoritative.
        The optional sample_rate is only a fallback for non-WAV input.
        """

        if not audio_data:
            _log("[AudioOutput ERROR] Empty audio_data.")
            return {
                "success": False,
                "error": "Empty audio data",
                "playback_started": False,
            }

        try:
            # ----------------------------------------------------------
            # Decode
            # ----------------------------------------------------------
            if audio_data[:4] == b"RIFF" and audio_data[8:12] == b"WAVE":
                audio_float32, rate, channels = self._decode_wav(audio_data)
            else:
                # Backward-compatible raw float32 input.
                rate = int(sample_rate or self.default_sample_rate)
                channels = self.default_channels

                audio_float32 = np.frombuffer(
                    audio_data,
                    dtype=np.float32,
                ).copy()

                audio_float32 = np.ascontiguousarray(
                    audio_float32,
                    dtype=np.float32,
                )

            audio_float32 = np.clip(
                audio_float32,
                -1.0,
                1.0,
            ).astype(np.float32, copy=False)

            # ----------------------------------------------------------
            # Diagnostics
            # ----------------------------------------------------------
            frame_count = (
                audio_float32.shape[0]
                if audio_float32.ndim > 1
                else audio_float32.size
            )

            duration_ms = round(
                (frame_count / rate) * 1000.0,
                2,
            )

            flat = audio_float32.reshape(-1)

            rms = float(
                np.sqrt(
                    np.mean(
                        np.square(flat),
                        dtype=np.float64,
                    )
                )
            ) if flat.size else 0.0

            peak = (
                float(np.max(np.abs(flat)))
                if flat.size
                else 0.0
            )

            _log("[TTS AUDIO]")
            _log(f"  Sample rate:  {rate} Hz")
            _log(f"  Channels:     {channels}")
            _log(f"  Frames:       {frame_count}")
            _log(f"  Duration:     {duration_ms} ms")
            _log(f"  dtype:        {audio_float32.dtype}")
            _log(f"  contiguous:   {audio_float32.flags['C_CONTIGUOUS']}")
            _log(f"  RMS:          {rms:.6f}")
            _log(f"  Peak:         {peak:.6f}")

            if flat.size == 0:
                raise ValueError("Decoded audio contains zero samples.")

            if rms < 1e-6:
                _log(
                    "[AudioOutput WARNING] RMS is near zero."
                )

            # ----------------------------------------------------------
            # Select device
            # ----------------------------------------------------------
            device_id = self.selected_device_id

            if device_id is not None:
                dev_info = sd.query_devices(device_id)
                dev_name = dev_info.get("name", "unknown")
                max_channels = int(
                    dev_info.get("max_output_channels", 0)
                )

                if max_channels < channels:
                    raise ValueError(
                        f"Device [{device_id}] supports only "
                        f"{max_channels} output channel(s), "
                        f"but audio has {channels}."
                    )
            else:
                dev_info = sd.query_devices(kind="output")
                dev_name = dev_info.get("name", "default")

            _log(
                f"[Speaker] Output device: "
                f"[{device_id if device_id is not None else 'default'}] "
                f"{dev_name}"
            )
            _log(f"[Speaker] Sample rate:    {rate} Hz")
            _log(f"[Speaker] Channels:       {channels}")
            _log(f"[Speaker] Duration:       {duration_ms} ms")

            # ----------------------------------------------------------
            # Playback
            # ----------------------------------------------------------
            #
            # RawOutputStream avoids sd.play's convenience-layer handling.
            # This sends our already-decoded float32 PCM directly.
            # ----------------------------------------------------------
            with self._lock:
                stream = sd.RawOutputStream(
                    samplerate=rate,
                    channels=channels,
                    dtype="float32",
                    device=device_id,
                    blocksize=0,
                )

                try:
                    stream.start()
                    _log("[Speaker] Playback started")

                    # RawOutputStream.write() accepts contiguous float32
                    # bytes directly. This avoids another dtype conversion.
                    stream.write(
                        np.ascontiguousarray(
                            audio_float32,
                            dtype=np.float32,
                        ).tobytes()
                    )

                    stream.stop()
                    _log("[Speaker] Playback completed")

                finally:
                    stream.close()

            return {
                "success": True,
                "sample_rate": rate,
                "channels": channels,
                "duration_ms": duration_ms,
                "rms": rms,
                "peak": peak,
                "device": dev_name,
                "playback_started": True,
                "error": None,
            }

        except Exception as e:
            err_msg = f"sounddevice playback error: {e}"
            _log(f"[AudioOutput ERROR] {err_msg}")

            try:
                sd.stop()
            except Exception:
                pass

            return {
                "success": False,
                "sample_rate": sample_rate or self.default_sample_rate,
                "duration_ms": 0.0,
                "rms": 0.0,
                "peak": 0.0,
                "device": None,
                "playback_started": False,
                "error": err_msg,
            }

    def stop(self):
        """Immediately stop active playback."""
        try:
            sd.stop()
        except Exception:
            pass

    def close(self):
        """Stop active playback."""
        self.stop()
