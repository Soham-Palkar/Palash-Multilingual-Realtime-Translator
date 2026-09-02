import os
import sys
import unittest

# Add parent directory to path to import translation module
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from translation.translator import Translator
from translation.languages import get_language_code

class TestTranslationEngine(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """Load the model once for all tests."""
        phrase_bank_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'verified_phrase_bank.json')
        cls.translator = Translator(phrase_bank_path=phrase_bank_path)

    def test_hindi_to_santali(self):
        result = self.translator.translate("बच्चों, इन फलों को गिनो।", "hin_Deva", "sat_Olck")
        self.assertTrue(result["success"])
        self.assertEqual(result["source_language"], "hin_Deva")
        self.assertEqual(result["target_language"], "sat_Olck")
        self.assertIsNotNone(result["translated_text"])
        self.assertGreater(len(result["translated_text"]), 0)

    def test_santali_to_hindi(self):
        # Santali for "Children, count these fruits." (Approximate machine output)
        result = self.translator.translate("ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ, ᱱᱚᱶᱟ ᱡᱚ ᱠᱚ ᱞᱮᱠᱷᱟᱭ ᱯᱮ᱾", "sat_Olck", "hin_Deva")
        self.assertTrue(result["success"])
        self.assertEqual(result["source_language"], "sat_Olck")
        self.assertEqual(result["target_language"], "hin_Deva")
        self.assertIsNotNone(result["translated_text"])
        self.assertGreater(len(result["translated_text"]), 0)

    def test_empty_input(self):
        result = self.translator.translate("", "hin_Deva", "sat_Olck")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"], "Empty input text")

    def test_unsupported_language_pair(self):
        result = self.translator.translate("Hello", "eng_Latn", "sat_Olck")
        self.assertFalse(result["success"])
        self.assertTrue(result["error"].startswith("Unsupported language pair"))

    def test_phrase_bank_match(self):
        # This exact string is in our mock verified_phrase_bank.json
        result = self.translator.translate("अपनी किताब खोलो।", "hin_Deva", "sat_Olck")
        self.assertTrue(result["success"])
        self.assertEqual(result["translation_source"], "verified_phrase")
        self.assertEqual(result["translated_text"], "ᱟᱢᱟᱜ ᱯᱚᱛᱚᱵ ᱡᱷᱤᱡᱽ ᱢᱮ᱾")

    def test_phrase_bank_fallback(self):
        # This is NOT in the phrase bank, should fall back to indictrans2
        result = self.translator.translate("मेरा नाम राम है।", "hin_Deva", "sat_Olck")
        self.assertTrue(result["success"])
        self.assertEqual(result["translation_source"], "indictrans2")
        self.assertIsNotNone(result["translated_text"])

    def test_language_codes(self):
        self.assertEqual(get_language_code("hindi"), "hin_Deva")
        self.assertEqual(get_language_code("santali"), "sat_Olck")
        with self.assertRaises(KeyError):
            get_language_code("french")

if __name__ == "__main__":
    unittest.main()
