import unittest
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from voice.tts_interface import DummyTTSBackend
from voice.indic_parler_tts import IndicParlerTTSBackend, VOICE_DESCRIPTIONS


class TestTTS(unittest.TestCase):

    def test_dummy_tts_synthesis(self):
        backend = DummyTTSBackend()
        self.assertTrue(backend.is_language_supported("sat_Olck"))
        audio = backend.synthesize("नमस्ते बच्चों", "sat_Olck")
        self.assertIsNotNone(audio)
        self.assertEqual(len(audio), 32000)  # 1s 16kHz mono PCM16 = 32000 bytes

    def test_tts_language_support(self):
        backend = DummyTTSBackend()
        self.assertTrue(backend.is_language_supported("hin_Deva"))
        self.assertTrue(backend.is_language_supported("sat_Olck"))

    def test_indic_parler_tts_voice_descriptions(self):
        backend = IndicParlerTTSBackend(lazy_load=True)
        self.assertTrue(backend.is_language_supported("sat_Olck"))
        self.assertTrue(backend.is_language_supported("hin_Deva"))
        self.assertFalse(backend.is_language_supported("eng_Latn"))

        desc_sat = backend.get_voice_description("sat_Olck")
        self.assertIn("Arjun", desc_sat)

        desc_hi = backend.get_voice_description("hin_Deva")
        self.assertIn("Sunita", desc_hi)

    def test_tts_empty_text_validation(self):
        backend = IndicParlerTTSBackend(lazy_load=True)
        # Empty text should return None cleanly without raising exception
        self.assertIsNone(backend.synthesize("", "sat_Olck"))
        self.assertIsNone(backend.synthesize("   ", "sat_Olck"))

    def test_tts_unsupported_language_validation(self):
        backend = IndicParlerTTSBackend(lazy_load=True)
        self.assertIsNone(backend.synthesize("Test", "unsupported_lang"))


if __name__ == "__main__":
    unittest.main()
