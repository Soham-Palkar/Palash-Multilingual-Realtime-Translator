import json
from abc import ABC, abstractmethod
from typing import Optional


class ASRResult:
    def __init__(self, text: str, is_final: bool):
        self.text = text
        self.is_final = is_final


class ASREngine(ABC):
    """
    Abstract interface for offline Automatic Speech Recognition (ASR).
    Supports language inquiry and streaming PCM audio processing.
    """
    @abstractmethod
    def start_stream(self):
        """Initializes or resets the ASR recognition stream."""
        pass

    @abstractmethod
    def accept_audio(self, audio_chunk: bytes) -> bool:
        """
        Feeds PCM audio into the recognizer.
        Returns True if a final result is ready.
        """
        pass

    @abstractmethod
    def get_partial_result(self) -> ASRResult:
        """Returns the current partial transcription."""
        pass

    @abstractmethod
    def get_final_result(self) -> ASRResult:
        """Returns the finalized transcription for the utterance."""
        pass

    @abstractmethod
    def stop_stream(self):
        """Cleans up the ASR stream."""
        pass

    def supports_language(self, language_code: str) -> bool:
        """
        Returns True if the ASR backend supports recognition for the given language code.
        Defaults to checking for Hindi ('hin_Deva', 'hi').
        """
        norm = language_code.lower()
        return norm in ("hi", "hin_deva", "hindi")


class VoskASRBackend(ASREngine):
    """
    Development ASR backend using Vosk (offline).
    Requires a downloaded Vosk model to function.
    """
    def __init__(self, model_path: str, sample_rate: int = 16000, language: str = "hi"):
        try:
            from vosk import Model, KaldiRecognizer
        except ImportError:
            raise ImportError("Please install vosk ('pip install vosk') to use this backend.")

        self.model = Model(model_path)
        self.sample_rate = sample_rate
        self.language = language
        self.recognizer = None

    def supports_language(self, language_code: str) -> bool:
        norm = language_code.lower()
        if norm in ("hi", "hin_deva"):
            return self.language in ("hi", "hin_deva")
        return False

    def start_stream(self):
        from vosk import KaldiRecognizer
        self.recognizer = KaldiRecognizer(self.model, self.sample_rate)

    def accept_audio(self, audio_chunk: bytes) -> bool:
        if not self.recognizer:
            raise RuntimeError("ASR stream not started.")
        return self.recognizer.AcceptWaveform(audio_chunk)

    def get_partial_result(self) -> ASRResult:
        if not self.recognizer:
            return ASRResult("", False)
        res = json.loads(self.recognizer.PartialResult())
        return ASRResult(res.get("partial", ""), False)

    def get_final_result(self) -> ASRResult:
        if not self.recognizer:
            return ASRResult("", True)
        res = json.loads(self.recognizer.Result())
        return ASRResult(res.get("text", ""), True)

    def stop_stream(self):
        self.recognizer = None


class DummyASRBackend(ASREngine):
    """Dummy ASR backend for development without models."""
    def __init__(self):
        self.active = False

    def supports_language(self, language_code: str) -> bool:
        norm = language_code.lower()
        return norm in ("hi", "hin_deva")

    def start_stream(self):
        self.active = True

    def accept_audio(self, audio_chunk: bytes) -> bool:
        return False

    def get_partial_result(self) -> ASRResult:
        return ASRResult("बच्चों...", False)

    def get_final_result(self) -> ASRResult:
        return ASRResult("बच्चों, इन फलों को गिनो।", True)

    def stop_stream(self):
        self.active = False
