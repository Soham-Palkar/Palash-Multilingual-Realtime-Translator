from abc import ABC, abstractmethod
from typing import Optional

class TTSEngine(ABC):
    """
    Abstract interface for offline Text-to-Speech synthesis.
    Implementations can be swapped (Piper, sherpa-onnx TTS, etc.) without changing the pipeline.
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


class PiperTTSBackend(TTSEngine):
    """
    Offline TTS backend using Piper (https://github.com/rhasspy/piper).
    Requires a downloaded Piper voice model.
    
    Status:
        Hindi: Piper has Hindi voices available.
        Santali: No known Piper voice exists. BLOCKED.
    """
    def __init__(self, model_path: Optional[str] = None, config_path: Optional[str] = None):
        self.model_path = model_path
        self.config_path = config_path
        self._piper = None
        self._supported_languages = set()
        
        if model_path:
            try:
                from piper import PiperVoice
                self._piper = PiperVoice.load(model_path, config_path)
                # Determine language from config or model metadata
                self._supported_languages.add("hin_Deva")  # If Hindi model loaded
            except ImportError:
                print("Warning: piper-tts not installed. Install with 'pip install piper-tts'.")
            except Exception as e:
                print(f"Warning: Failed to load Piper voice model: {e}")

    def synthesize(self, text: str, language: str) -> Optional[bytes]:
        if not self._piper:
            print(f"TTS: Piper not loaded. Cannot synthesize: '{text[:50]}...'")
            return None
        if not self.is_language_supported(language):
            print(f"TTS: Language '{language}' not supported by loaded Piper model.")
            return None
        try:
            import io
            import wave
            audio_buffer = io.BytesIO()
            with wave.open(audio_buffer, 'wb') as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)
                wav_file.setframerate(16000)
                self._piper.synthesize(text, wav_file)
            audio_buffer.seek(0)
            # Read raw PCM from the wav
            with wave.open(audio_buffer, 'rb') as wav_file:
                pcm_data = wav_file.readframes(wav_file.getnframes())
            return pcm_data
        except Exception as e:
            print(f"TTS synthesis failed: {e}")
            return None

    def is_language_supported(self, language: str) -> bool:
        return language in self._supported_languages


class DummyTTSBackend(TTSEngine):
    """
    Dummy TTS backend for pipeline testing.
    Returns silence bytes so the pipeline can complete without a real TTS model.
    """
    def __init__(self):
        pass

    def synthesize(self, text: str, language: str) -> Optional[bytes]:
        print(f"[DummyTTS] Would synthesize ({language}): {text}")
        # Return 1 second of silence (16kHz, 16-bit, mono)
        return b'\x00\x00' * 16000

    def is_language_supported(self, language: str) -> bool:
        return True
