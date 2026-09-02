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

class VoskASRBackend(ASREngine):
    """
    Development ASR backend using Vosk (offline).
    Requires a downloaded Vosk model to function.
    """
    def __init__(self, model_path: str, sample_rate: int = 16000):
        try:
            from vosk import Model, KaldiRecognizer
        except ImportError:
            raise ImportError("Please install vosk ('pip install vosk') to use this backend.")
            
        self.model = Model(model_path)
        self.sample_rate = sample_rate
        self.recognizer = None

    def start_stream(self):
        from vosk import KaldiRecognizer
        self.recognizer = KaldiRecognizer(self.model, self.sample_rate)

    def accept_audio(self, audio_chunk: bytes) -> bool:
        if not self.recognizer:
            raise RuntimeError("ASR stream not started.")
        # Vosk accept_waveform returns True if a sentence boundary was detected
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

# Dummy Backend for testing pipeline structure without downloading 1GB ASR models
class DummyASRBackend(ASREngine):
    """Dummy ASR backend for development without models."""
    def __init__(self):
        self.active = False
        
    def start_stream(self):
        self.active = True
        
    def accept_audio(self, audio_chunk: bytes) -> bool:
        # Just simulate waiting for enough audio
        return False
        
    def get_partial_result(self) -> ASRResult:
        return ASRResult("बच्चों...", False)
        
    def get_final_result(self) -> ASRResult:
        return ASRResult("बच्चों, इन फलों को गिनो।", True)
        
    def stop_stream(self):
        self.active = False
