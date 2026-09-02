import os
import json
import time
import torch
from typing import Dict, Any, Optional
from difflib import SequenceMatcher

from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
from IndicTransToolkit.processor import IndicProcessor

from .languages import LANGUAGES, get_language_code

MODEL_NAME = "ai4bharat/indictrans2-indic-indic-dist-320M"
SUPPORTED_PAIRS = {
    ("hin_Deva", "sat_Olck"),
    ("sat_Olck", "hin_Deva")
}

class Translator:
    def __init__(self, phrase_bank_path: Optional[str] = None):
        """
        Initializes the Translator engine. Loads the model, tokenizer, and processor once.
        """
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model = None
        self.tokenizer = None
        self.ip = None
        self.phrase_bank = []
        
        self._load_phrase_bank(phrase_bank_path)
        self._initialize_model()

    def _initialize_model(self):
        """Loads IndicTrans2 model, tokenizer, and processor into memory."""
        try:
            self.tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True)
            self.model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME, trust_remote_code=True)
            self.model = self.model.to(self.device)
            self.model.eval()
            self.ip = IndicProcessor(inference=True)
        except Exception as e:
            raise RuntimeError(f"Failed to load translation model: {e}")

    def _load_phrase_bank(self, phrase_bank_path: Optional[str]):
        """Loads the verified phrase bank if available."""
        if phrase_bank_path and os.path.exists(phrase_bank_path):
            try:
                with open(phrase_bank_path, "r", encoding="utf-8") as f:
                    self.phrase_bank = json.load(f)
            except Exception as e:
                print(f"Warning: Failed to load phrase bank from {phrase_bank_path}: {e}")

    def _preprocess(self, text: str) -> str:
        """
        Cleans unnecessary whitespace and preserves meaningful punctuation/unicode.
        """
        if not text:
            return ""
        # Basic normalization (remove excessive spaces)
        text = " ".join(text.split())
        return text

    def _postprocess(self, text: str) -> str:
        """
        Cleans up spacing and model artifacts from the generated text.
        """
        if not text:
            return ""
        # Remove extra spaces before punctuation
        text = text.replace(" ।", "।").replace(" ,", ",").replace(" ?", "?")
        return text

    def _match_phrase(self, text: str, source: str, target: str) -> Optional[str]:
        """
        Lightweight fuzzy matching against the verified phrase bank.
        Returns the verified translation if a high-confidence match is found.
        """
        if not self.phrase_bank:
            return None
        
        # Currently, the phrase bank only supports Hindi -> Santali
        if source != "hin_Deva" or target != "sat_Olck":
            return None

        best_match = None
        highest_ratio = 0.0

        for entry in self.phrase_bank:
            if not entry.get("verified", False) or not entry.get("verified_santali"):
                continue
            
            hindi_text = entry.get("hindi", "")
            ratio = SequenceMatcher(None, text, hindi_text).ratio()
            
            if ratio > highest_ratio:
                highest_ratio = ratio
                best_match = entry.get("verified_santali")

        # Threshold for high confidence match
        if highest_ratio >= 0.95:
            return best_match
            
        return None

    def translate(self, text: str, source: str, target: str, context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Translates text from source language to target language.
        
        Args:
            text: The text to translate.
            source: Source language code (e.g., 'hin_Deva').
            target: Target language code (e.g., 'sat_Olck').
            context: Optional contextual information for the translation.
            
        Returns:
            A structured dictionary containing translation results, latency, and status.
        """
        start_time = time.time()
        
        result = {
            "source_text": text,
            "translated_text": None,
            "source_language": source,
            "target_language": target,
            "translation_source": None,
            "latency_ms": 0,
            "success": False,
            "error": None
        }

        # 1. Validation
        if not text or not text.strip():
            result["error"] = "Empty input text"
            result["latency_ms"] = int((time.time() - start_time) * 1000)
            return result

        if (source, target) not in SUPPORTED_PAIRS:
            result["error"] = f"Unsupported language pair: {source} -> {target}"
            result["latency_ms"] = int((time.time() - start_time) * 1000)
            return result

        try:
            # 2. Preprocessing
            clean_text = self._preprocess(text)

            # 3. Phrase Matching
            matched_translation = self._match_phrase(clean_text, source, target)
            if matched_translation:
                result["translated_text"] = matched_translation
                result["translation_source"] = "verified_phrase"
                result["success"] = True
                result["latency_ms"] = int((time.time() - start_time) * 1000)
                return result

            # 4. Neural Translation (IndicTrans2)
            batch = self.ip.preprocess_batch([clean_text], src_lang=source, tgt_lang=target)
            
            inputs = self.tokenizer(
                batch,
                truncation=True,
                padding="longest",
                return_tensors="pt",
                return_attention_mask=True,
            ).to(self.device)

            with torch.no_grad():
                generated_tokens = self.model.generate(
                    **inputs,
                    use_cache=True,
                    min_length=0,
                    max_length=256,
                    num_beams=5,
                    num_return_sequences=1,
                )

            translations = self.tokenizer.batch_decode(
                generated_tokens,
                skip_special_tokens=True,
                clean_up_tokenization_spaces=True,
            )

            postprocessed_translations = self.ip.postprocess_batch(translations, lang=target)
            final_text = self._postprocess(postprocessed_translations[0])

            result["translated_text"] = final_text
            result["translation_source"] = "indictrans2"
            result["success"] = True

        except Exception as e:
            result["error"] = f"Translation inference failed: {e}"
            result["success"] = False

        result["latency_ms"] = int((time.time() - start_time) * 1000)
        return result