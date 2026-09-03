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
        Initializes the Translator engine.

        The model, tokenizer and IndicProcessor are loaded once and
        reused for all translation requests.
        """

        self.device = "cuda" if torch.cuda.is_available() else "cpu"

        self.model = None
        self.tokenizer = None
        self.ip = None

        self.phrase_bank = []

        self._load_phrase_bank(phrase_bank_path)
        self._initialize_model()

    # ---------------------------------------------------------
    # MODEL INITIALIZATION
    # ---------------------------------------------------------

    def _initialize_model(self):
        """Load IndicTrans2 model, tokenizer and processor."""

        try:
            print(f"[Translator] Loading model: {MODEL_NAME}")
            print(f"[Translator] Device: {self.device}")

            self.tokenizer = AutoTokenizer.from_pretrained(
                MODEL_NAME,
                trust_remote_code=True
            )

            self.model = AutoModelForSeq2SeqLM.from_pretrained(
                MODEL_NAME,
                trust_remote_code=True
            )

            self.model = self.model.to(self.device)
            self.model.eval()

            self.ip = IndicProcessor(inference=True)

            print("[Translator] Model loaded successfully.")

        except Exception as e:
            raise RuntimeError(
                f"Failed to load translation model: {e}"
            )

    # ---------------------------------------------------------
    # PHRASE BANK
    # ---------------------------------------------------------

    def _load_phrase_bank(self, phrase_bank_path: Optional[str]):
        """Load verified classroom phrase bank if available."""

        if not phrase_bank_path:
            return

        if not os.path.exists(phrase_bank_path):
            print(
                f"[Translator] Phrase bank not found: "
                f"{phrase_bank_path}"
            )
            return

        try:
            with open(
                phrase_bank_path,
                "r",
                encoding="utf-8"
            ) as f:

                self.phrase_bank = json.load(f)

            print(
                f"[Translator] Loaded "
                f"{len(self.phrase_bank)} phrase-bank entries."
            )

        except Exception as e:
            print(
                f"[Translator] Warning: Failed to load "
                f"phrase bank: {e}"
            )

    # ---------------------------------------------------------
    # PREPROCESSING
    # ---------------------------------------------------------

    def _preprocess(self, text: str) -> str:
        """
        Normalize unnecessary whitespace while preserving
        Devanagari / Ol Chiki Unicode and punctuation.
        """

        if not text:
            return ""

        text = " ".join(text.split())

        return text.strip()

    # ---------------------------------------------------------
    # POSTPROCESSING
    # ---------------------------------------------------------

    def _postprocess(self, text: str) -> str:
        """
        Clean spacing and obvious generation artifacts.
        """

        if not text:
            return ""

        text = text.strip()

        # Remove unwanted spaces before punctuation.
        text = text.replace(" ।", "।")
        text = text.replace(" ,", ",")
        text = text.replace(" ?", "?")
        text = text.replace(" !", "!")
        text = text.replace(" :", ":")
        text = text.replace(" ;", ";")

        # Remove repeated whitespace.
        text = " ".join(text.split())

        return text

    # ---------------------------------------------------------
    # REPETITION PROTECTION
    # ---------------------------------------------------------

    def _remove_repeated_phrases(self, text: str) -> str:
        """
        Protect against pathological repetitive generation.

        Example bad output:

        कैसे हो, कैसे हो, कैसे हो, कैसे हो, ...

        This is intentionally conservative so that normal
        repeated words in legitimate sentences are preserved.
        """

        if not text:
            return text

        words = text.split()

        # Very short output does not need this processing.
        if len(words) < 6:
            return text

        cleaned = []

        # Maximum number of consecutive identical tokens.
        consecutive_count = 0
        previous = None

        for word in words:

            if word == previous:
                consecutive_count += 1
            else:
                consecutive_count = 1

            # Do not allow extreme token repetition.
            if consecutive_count <= 3:
                cleaned.append(word)

            previous = word

        text = " ".join(cleaned)

        # Detect repeated multi-word sequence.
        words = text.split()

        if len(words) >= 12:

            for sequence_length in range(1, 6):

                if len(words) < sequence_length * 4:
                    continue

                last_sequence = words[-sequence_length:]

                repetitions = 1

                index = len(words) - sequence_length * 2

                while index >= 0:

                    previous_sequence = words[
                        index:index + sequence_length
                    ]

                    if previous_sequence == last_sequence:
                        repetitions += 1
                        index -= sequence_length
                    else:
                        break

                # If the same phrase repeats excessively,
                # keep only the first few occurrences.
                if repetitions >= 4:

                    max_words = sequence_length * 3

                    words = words[:max_words]

                    text = " ".join(words)

                    break

        return text

    # ---------------------------------------------------------
    # PHRASE MATCHING
    # ---------------------------------------------------------

    def _match_phrase(
        self,
        text: str,
        source: str,
        target: str
    ) -> Optional[str]:
        """
        Match against verified phrase bank.

        Only high-confidence matches are returned.
        """

        if not self.phrase_bank:
            return None

        # Current verified phrase bank supports Hindi -> Santali.
        if source != "hin_Deva" or target != "sat_Olck":
            return None

        best_match = None
        highest_ratio = 0.0

        for entry in self.phrase_bank:

            if not entry.get("verified", False):
                continue

            verified_santali = entry.get(
                "verified_santali"
            )

            if not verified_santali:
                continue

            hindi_text = entry.get("hindi", "")

            if not hindi_text:
                continue

            ratio = SequenceMatcher(
                None,
                text,
                hindi_text
            ).ratio()

            if ratio > highest_ratio:
                highest_ratio = ratio
                best_match = verified_santali

        if highest_ratio >= 0.95:
            return best_match

        return None

    # ---------------------------------------------------------
    # GENERATION LENGTH
    # ---------------------------------------------------------

    def _get_generation_length(
        self,
        input_token_count: int
    ):
        """
        Select a reasonable maximum output length based on
        the input size.

        This prevents very short inputs such as:

            "है"
            "कैसे हो"

        from generating hundreds of repeated tokens.

        Longer classroom sentences still get enough room.
        """

        if input_token_count <= 8:
            return 32

        if input_token_count <= 20:
            return 64

        if input_token_count <= 40:
            return 128

        return 192

    # ---------------------------------------------------------
    # MAIN TRANSLATION
    # ---------------------------------------------------------

    def translate(
        self,
        text: str,
        source: str,
        target: str,
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:

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

        # -----------------------------------------------------
        # VALIDATION
        # -----------------------------------------------------

        if not text or not text.strip():

            result["error"] = "Empty input text"

            result["latency_ms"] = int(
                (time.time() - start_time) * 1000
            )

            return result

        if (source, target) not in SUPPORTED_PAIRS:

            result["error"] = (
                f"Unsupported language pair: "
                f"{source} -> {target}"
            )

            result["latency_ms"] = int(
                (time.time() - start_time) * 1000
            )

            return result

        try:

            # -------------------------------------------------
            # PREPROCESS
            # -------------------------------------------------

            clean_text = self._preprocess(text)

            # -------------------------------------------------
            # VERIFIED PHRASE MATCH
            # -------------------------------------------------

            matched_translation = self._match_phrase(
                clean_text,
                source,
                target
            )

            if matched_translation:

                result["translated_text"] = (
                    matched_translation
                )

                result["translation_source"] = (
                    "verified_phrase"
                )

                result["success"] = True

                result["latency_ms"] = int(
                    (time.time() - start_time) * 1000
                )

                return result

            # -------------------------------------------------
            # INDICPROCESSOR
            # -------------------------------------------------

            batch = self.ip.preprocess_batch(
                [clean_text],
                src_lang=source,
                tgt_lang=target
            )

            # -------------------------------------------------
            # TOKENIZATION
            # -------------------------------------------------

            inputs = self.tokenizer(
                batch,
                truncation=True,
                padding="longest",
                return_tensors="pt",
                return_attention_mask=True,
            ).to(self.device)

            # Determine input length.
            input_token_count = (
                inputs["input_ids"].shape[-1]
            )

            max_generation_length = (
                self._get_generation_length(
                    input_token_count
                )
            )

            # -------------------------------------------------
            # TRANSLATION INFERENCE
            # -------------------------------------------------

            with torch.no_grad():

                generated_tokens = self.model.generate(
                    **inputs,

                    use_cache=True,

                    # Prevent pathological long generation.
                    max_length=max_generation_length,

                    # Beam search.
                    num_beams=5,
                    num_return_sequences=1,

                    # Encourage generation to stop naturally.
                    early_stopping=True,

                    # Prevent repeating the same n-gram.
                    no_repeat_ngram_size=3,

                    # Small penalty against repeating tokens.
                    repetition_penalty=1.05,
                )

            # -------------------------------------------------
            # DECODE
            # -------------------------------------------------

            translations = self.tokenizer.batch_decode(
                generated_tokens,
                skip_special_tokens=True,
                clean_up_tokenization_spaces=True,
            )

            if not translations:

                raise RuntimeError(
                    "Translation model returned no output."
                )

            # -------------------------------------------------
            # INDICPROCESSOR POSTPROCESS
            # -------------------------------------------------

            postprocessed_translations = (
                self.ip.postprocess_batch(
                    translations,
                    lang=target
                )
            )

            if not postprocessed_translations:

                raise RuntimeError(
                    "Translation postprocessing returned "
                    "no output."
                )

            final_text = self._postprocess(
                postprocessed_translations[0]
            )

            # -------------------------------------------------
            # REPETITION CLEANUP
            # -------------------------------------------------

            final_text = self._remove_repeated_phrases(
                final_text
            )

            # -------------------------------------------------
            # EMPTY OUTPUT CHECK
            # -------------------------------------------------

            if not final_text:

                raise RuntimeError(
                    "Translation model produced empty output."
                )

            # -------------------------------------------------
            # RESULT
            # -------------------------------------------------

            result["translated_text"] = final_text

            result["translation_source"] = "indictrans2"

            result["success"] = True

        except Exception as e:

            result["error"] = (
                f"Translation inference failed: {e}"
            )

            result["success"] = False

        # -----------------------------------------------------
        # LATENCY
        # -----------------------------------------------------

        result["latency_ms"] = int(
            (time.time() - start_time) * 1000
        )

        return result