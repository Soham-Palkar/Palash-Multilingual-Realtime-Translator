import os
import tempfile
import wave
from typing import Optional

import torch
import nemo.collections.asr as nemo_asr

from voice.asr_interface import ASREngine, ASRResult


class IndicConformerASRBackend(ASREngine):
    """
    IndicConformer ASR backend.

    Audio input:
        PCM16, mono, 16 kHz

    Current implementation:
        Buffers audio chunks and performs inference when
        get_final_result() is called.

    This allows it to work with the existing ASREngine
    interface while we later connect it to VAD.
    """

    def __init__(
        self,
        model_name: str = "ai4bharat/indicconformer_stt_hi_hybrid_rnnt_large",
        language_id: str = "hi",
        sample_rate: int = 16000,
        decoder: str = "ctc",
    ):
        self.model_name = model_name
        self.language_id = language_id
        self.sample_rate = sample_rate
        self.decoder = decoder

        self.device = torch.device(
            "cuda" if torch.cuda.is_available() else "cpu"
        )

        print(f"Loading IndicConformer: {model_name}")
        print(f"Device: {self.device}")

        self.model = nemo_asr.models.ASRModel.from_pretrained(
            model_name
        )

        self.model.freeze()
        self.model = self.model.to(self.device)

        if decoder not in ("ctc", "rnnt"):
            raise ValueError("decoder must be 'ctc' or 'rnnt'")

        self.model.cur_decoder = decoder

        self.audio_buffer = bytearray()
        self.active = False
        self._final_result: Optional[ASRResult] = None

        print("IndicConformer backend ready.")

    def start_stream(self):
        """Start a new utterance."""
        self.audio_buffer.clear()
        self._final_result = None
        self.active = True

    def accept_audio(self, audio_chunk: bytes) -> bool:
        """
        Accept PCM16 audio from microphone/VAD.

        Returns True only when an internal final result
        is available. VAD will normally determine the
        actual end of speech.
        """
        if not self.active:
            raise RuntimeError("ASR stream not started.")

        if not isinstance(audio_chunk, bytes):
            raise TypeError("audio_chunk must be bytes")

        self.audio_buffer.extend(audio_chunk)

        # IndicConformer currently performs utterance-level
        # inference rather than true streaming inference.
        return False

    def get_partial_result(self) -> ASRResult:
        """
        IndicConformer backend currently does not expose
        partial streaming text through this interface.
        """
        if self._final_result is not None:
            return self._final_result

        return ASRResult("", False)

    def get_final_result(self) -> ASRResult:
        """
        Run IndicConformer on the accumulated utterance.
        """

        if not self.active:
            return ASRResult("", True)

        if not self.audio_buffer:
            return ASRResult("", True)

        # Write PCM16 bytes to a temporary WAV file.
        temp_path = None

        try:
            with tempfile.NamedTemporaryFile(
                suffix=".wav",
                delete=False
            ) as temp_audio:

                temp_path = temp_audio.name

            with wave.open(temp_path, "wb") as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)  # PCM16 = 2 bytes
                wav_file.setframerate(self.sample_rate)
                wav_file.writeframes(bytes(self.audio_buffer))

            print("Running IndicConformer inference...")

            results = self.model.transcribe(
                [temp_path],
                batch_size=1,
                logprobs=False,
                language_id=self.language_id,
                verbose=False,
            )

            text = results[0] if results else ""
            text = str(text).strip()

            self._final_result = ASRResult(
                text=text,
                is_final=True
            )

            return self._final_result

        finally:
            if temp_path and os.path.exists(temp_path):
                os.remove(temp_path)

    def stop_stream(self):
        """Stop current utterance and clear audio."""
        self.audio_buffer.clear()
        self.active = False
        self._final_result = None