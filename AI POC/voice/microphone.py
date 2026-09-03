import pyaudio
from typing import List, Dict, Optional


class Microphone:
    """
    Physical microphone capture using PyAudio.

    Audio format:
        - PCM16
        - Mono
        - 16 kHz

    Designed for the PALASH real-time voice pipeline.
    """

    def __init__(
        self,
        rate: int = 16000,
        channels: int = 1,
        chunk_size: int = 1024
    ):
        self.rate = rate
        self.channels = channels
        self.chunk_size = chunk_size
        self.format = pyaudio.paInt16

        self.p = pyaudio.PyAudio()
        self.stream = None
        self.selected_device_id: Optional[int] = None

    # ---------------------------------------------------------
    # DEVICE DISCOVERY
    # ---------------------------------------------------------

    def list_audio_inputs(self) -> List[Dict]:
        """
        Return all available physical microphone input devices.
        """

        inputs = []

        for i in range(self.p.get_device_count()):
            try:
                dev_info = self.p.get_device_info_by_index(i)

                if dev_info.get("maxInputChannels", 0) > 0:
                    inputs.append({
                        "id": i,
                        "name": dev_info.get("name", "Unknown"),
                        "channels": int(
                            dev_info.get("maxInputChannels", 0)
                        ),
                        "sample_rate": int(
                            dev_info.get("defaultSampleRate", 16000)
                        ),
                    })

            except Exception as e:
                print(f"[Microphone] Could not inspect device {i}: {e}")

        return inputs

    def print_audio_inputs(self):
        """Print available microphone devices."""

        inputs = self.list_audio_inputs()

        print("\nAvailable microphone inputs:")
        print("-" * 60)

        for device in inputs:
            print(
                f"ID {device['id']}: "
                f"{device['name']} | "
                f"channels={device['channels']} | "
                f"default_rate={device['sample_rate']}"
            )

        print("-" * 60)

    # ---------------------------------------------------------
    # DEVICE SELECTION
    # ---------------------------------------------------------

    def select_audio_input(self, device_id: Optional[int] = None):
        """
        Select microphone.

        If device_id is supplied:
            use that exact device.

        Otherwise:
            prefer USB/external microphones.
            fall back to the first available input.
        """

        inputs = self.list_audio_inputs()

        if not inputs:
            raise RuntimeError(
                "No microphone input devices found."
            )

        # Explicit device selection
        if device_id is not None:

            matching = [
                d for d in inputs
                if d["id"] == device_id
            ]

            if not matching:
                raise ValueError(
                    f"Microphone device ID {device_id} "
                    f"was not found."
                )

            self.selected_device_id = device_id

        else:

            # Prefer external / USB microphones
            external_keywords = (
                "USB",
                "External",
                "Headset",
                "Microphone"
            )

            external = [
                d for d in inputs
                if any(
                    keyword.lower() in d["name"].lower()
                    for keyword in external_keywords
                )
            ]

            if external:
                self.selected_device_id = external[0]["id"]
            else:
                self.selected_device_id = inputs[0]["id"]

        selected = next(
            d for d in inputs
            if d["id"] == self.selected_device_id
        )

        print(
            f"[Microphone] Selected: "
            f"{selected['name']} "
            f"(ID {selected['id']})"
        )

    # ---------------------------------------------------------
    # STREAM
    # ---------------------------------------------------------

    def start(self):
        """Open the physical microphone stream."""

        if self.stream is not None:
            return

        if self.selected_device_id is None:
            self.select_audio_input()

        try:
            self.stream = self.p.open(
                format=self.format,
                channels=self.channels,
                rate=self.rate,
                input=True,
                input_device_index=self.selected_device_id,
                frames_per_buffer=self.chunk_size,
            )

            print(
                f"[Microphone] Stream started "
                f"({self.rate} Hz, "
                f"{self.channels} channel, "
                f"PCM16)"
            )

        except Exception as e:
            self.stream = None

            raise RuntimeError(
                f"Failed to initialize microphone: {e}"
            )

    def is_active(self) -> bool:
        """Return True if microphone stream is active."""

        return (
            self.stream is not None
            and self.stream.is_active()
        )

    def read_chunk(self) -> bytes:
        """
        Read one PCM16 audio chunk.

        Returns:
            bytes
        """

        if not self.is_active():
            raise RuntimeError(
                "Microphone stream is not active."
            )

        return self.stream.read(
            self.chunk_size,
            exception_on_overflow=False
        )

    # ---------------------------------------------------------
    # CLEANUP
    # ---------------------------------------------------------

    def stop(self):
        """Stop the microphone stream."""

        if self.stream is not None:

            try:
                self.stream.stop_stream()
                self.stream.close()
            except Exception as e:
                print(
                    f"[Microphone] Stop warning: {e}"
                )

            self.stream = None

            print(
                "[Microphone] Stream stopped."
            )

    def close(self):
        """Release all PyAudio resources."""

        self.stop()

        if self.p is not None:
            try:
                self.p.terminate()
            except Exception:
                pass

            self.p = None

    def __del__(self):
        try:
            self.close()
        except Exception:
            pass