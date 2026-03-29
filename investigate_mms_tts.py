#!/usr/bin/env python3
"""
Investigate Facebook MMS TTS model for Bisaya (Cebuano) support
"""

from transformers import VitsModel, AutoTokenizer
import torch
import json

def investigate_mms_tts():
    print("Loading Facebook MMS TTS model: facebook/mms-tts-1b-all")
    
    try:
        # Load the model
        model = VitsModel.from_pretrained("facebook/mms-tts-1b-all")
        print("✓ Model loaded successfully")
        
        # Load the tokenizer
        tokenizer = AutoTokenizer.from_pretrained("facebook/mms-tts-1b-all")
        print("✓ Tokenizer loaded successfully")
        
        # Get model configuration
        print("\n" + "="*50)
        print("MODEL CONFIGURATION")
        print("="*50)
        
        # Check if model has config attribute
        if hasattr(model, 'config'):
            config = model.config
            print(f"Model type: {config.model_type}")
            print(f"Vocab size: {config.vocab_size}")
            
            # Try to get language information
            if hasattr(config, 'languages'):
                print(f"Supported languages: {config.languages}")
            if hasattr(config, 'language_ids'):
                print(f"Language IDs: {config.language_ids}")
        
        # Check tokenizer for language information
        print("\n" + "="*50)
        print("TOKENIZER INFORMATION")
        print("="*50)
        
        if hasattr(tokenizer, 'vocab'):
            print(f"Tokenizer vocab size: {len(tokenizer.vocab)}")
        
        # Try to get language codes from tokenizer
        if hasattr(tokenizer, 'lang_code_to_id'):
            print(f"Language codes: {tokenizer.lang_code_to_id}")
        
        # Look for Bisaya/Cebuano related tokens or codes
        print("\n" + "="*50)
        print("SEARCHING FOR BISAYA/CEBUANO SUPPORT")
        print("="*50)
        
        bisaya_variants = ['ceb', 'bis', 'cebuan', 'bisaya', 'cebuano', 'phl']
        found_languages = []
        
        if hasattr(tokenizer, 'lang_code_to_id'):
            for variant in bisaya_variants:
                if variant in tokenizer.lang_code_to_id:
                    found_languages.append((variant, tokenizer.lang_code_to_id[variant]))
        
        if found_languages:
            print("✓ Found Bisaya/Cebuano support:")
            for lang_code, lang_id in found_languages:
                print(f"  - Language code: '{lang_code}' -> ID: {lang_id}")
        else:
            print("✗ No explicit Bisaya/Cebuano language codes found")
        
        # Try to get all available language codes
        print("\n" + "="*50)
        print("ALL AVAILABLE LANGUAGE CODES")
        print("="*50)
        
        if hasattr(tokenizer, 'lang_code_to_id'):
            lang_codes = list(tokenizer.lang_code_to_id.keys())
            print(f"Total languages supported: {len(lang_codes)}")
            print("Language codes:")
            for code in sorted(lang_codes):
                print(f"  - {code}")
        
        # Check model's repo files for language info
        print("\n" + "="*50)
        print("ADDITIONAL INVESTIGATION")
        print("="*50)
        
        # Try to access the model's repo information
        try:
            from huggingface_hub import HfApi, ModelInfo
            api = HfApi()
            model_info = api.model_info("facebook/mms-tts-1b-all")
            print(f"Model info: {model_info}")
            
            # Get tags
            if model_info.tags:
                print(f"Tags: {model_info.tags}")
            
            # Get card data
            if model_info.card_data:
                print(f"Card data: {model_info.card_data}")
                
        except Exception as e:
            print(f"Could not fetch additional model info: {e}")
        
        return model, tokenizer, found_languages
        
    except Exception as e:
        print(f"Error loading model: {e}")
        return None, None, []

if __name__ == "__main__":
    model, tokenizer, bisaya_support = investigate_mms_tts()
