"""
Language configuration for PALASH Multilingual Real-Time Translator.

This file centralizes all language codes to prevent hard-coding
across the project and easily allow adding new languages in the future
(e.g., Ho, Mundari).
"""

LANGUAGES = {
    "hindi": "hin_Deva",
    "santali": "sat_Olck",
    # "ho": "<future-code>",
    # "mundari": "<future-code>",
}

def get_language_code(language_name: str) -> str:
    """
    Returns the IndicTrans2 language code for a given language name.
    
    Args:
        language_name (str): The common name of the language (e.g., 'hindi', 'santali').
        
    Returns:
        str: The internal IndicTrans2 language code, or raises a KeyError if not supported.
    """
    code = LANGUAGES.get(language_name.lower())
    if not code:
        raise KeyError(f"Language '{language_name}' is not currently supported. Supported languages: {list(LANGUAGES.keys())}")
    return code
