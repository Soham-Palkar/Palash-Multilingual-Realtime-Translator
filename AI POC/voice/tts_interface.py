from abc import ABC, abstractmethod
from typing import Optional


class TTSEngine(ABC):
    """
    Abstract interface for offline Text-to-Speech synthesis.
    Implementations can be swapped (Indic Parler-TTS, Piper, sherpa-onnx TTS, etc.)
    without changing the pipeline.
    """

    @abstractmethod
    def synthesize(self, text: str, language: str) -> Optional[bytes]:
        """
        Synthesizes speech from text.

        Args:
            text: The text to speak.
            language: Language code (e.g., 'hin_Deva', 'sat_Olck').

        Returns:
            PCM audio bytes (mono, 16kHz, 16-bit) or None if synthesis fails.
        """
        pass

    @abstractmethod
    def is_language_supported(self, language: str) -> bool:
        """Returns True if the TTS engine has a voice for the given language."""
        pass


class DummyTTSBackend(TTSEngine):
    """
    Dummy TTS backend for pipeline testing.
    Returns silence bytes so the pipeline can complete without a real TTS model.
    """

    def __init__(self):
        pass

    def synthesize(self, text: str, language: str) -> Optional[bytes]:
        try:
            print(f"[DummyTTS] Would synthesize ({language}): {text[:30]}")
        except Exception:
            print(f"[DummyTTS] Would synthesize ({language}): [Unicode Text]")
        return b'\x00\x00' * 16000


    def is_language_supported(self, language: str) -> bool:
        return True
