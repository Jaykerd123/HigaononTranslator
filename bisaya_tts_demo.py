#!/usr/bin/env python3
"""
Bisaya TTS Demo using Facebook MMS TTS Model
This script demonstrates how to generate Bisaya audio using the facebook/mms-tts-1b-all model.

REQUIREMENTS:
pip install torch transformers scipy

USAGE:
python bisaya_tts_demo.py
"""

import torch
from transformers import VitsModel, AutoTokenizer
import scipy.io.wavfile
import os

def generate_bisaya_audio():
    """Generate audio for Bisaya phrases using MMS TTS model"""
    
    print("🎤 Bisaya Text-to-Speech Demo")
    print("=" * 50)
    
    try:
        # Load the multilingual MMS TTS model
        print("📥 Loading Facebook MMS TTS model...")
        model = VitsModel.from_pretrained("facebook/mms-tts-1b-all")
        tokenizer = AutoTokenizer.from_pretrained("facebook/mms-tts-1b-all")
        print("✅ Model loaded successfully!")
        print(f"📊 Model sampling rate: {model.config.sampling_rate} Hz")
        
        # Set language to Cebuano (Bisaya) - ISO 639-3 code: 'ceb'
        print("\n🌍 Setting language to Cebuano (Bisaya)...")
        tokenizer.set_target_language("ceb")
        print("✅ Language set to 'ceb' (Cebuano/Bisaya)")
        
        # Test Bisaya phrases with English translations
        bisaya_phrases = [
            ("Kumusta ka?", "How are you?"),
            ("Maayong adlaw.", "Good day."),
            ("Salamat kaayo.", "Thank you very much."),
            ("Unsa imong ngalan?", "What is your name?"),
            ("Nalingaw ko sa pagpangita sa imo.", "I was happy looking for you."),
            ("Gusto ko mogamit sa Bisaya nga pinulongan.", "I want to use the Bisaya language."),
            ("Kining awtoromobil kay daghan kwarta.", "This car is expensive."),
            ("Mangaon kita karon.", "Let's eat now.")
        ]
        
        print(f"\n🎵 Generating audio for {len(bisaya_phrases)} Bisaya phrases...")
        
        # Create output directory
        output_dir = "bisaya_audio_output"
        os.makedirs(output_dir, exist_ok=True)
        
        generated_files = []
        
        for i, (bisaya_text, english_translation) in enumerate(bisaya_phrases):
            print(f"\n📝 Phrase {i+1}:")
            print(f"   Bisaya: '{bisaya_text}'")
            print(f"   English: '{english_translation}'")
            
            # Tokenize the text
            inputs = tokenizer(bisaya_text, return_tensors="pt")
            
            # Generate audio waveform
            with torch.no_grad():
                output = model(**inputs).waveform
            
            # Convert to numpy array
            audio_array = output.numpy().flatten()
            
            # Save as WAV file
            filename = f"bisaya_{i+1:02d}_{bisaya_text.replace(' ', '_').replace('?', '')}.wav"
            filepath = os.path.join(output_dir, filename)
            
            scipy.io.wavfile.write(
                filepath, 
                rate=model.config.sampling_rate, 
                data=audio_array
            )
            
            duration = len(audio_array) / model.config.sampling_rate
            generated_files.append((filename, bisaya_text, english_translation, duration))
            
            print(f"   ✅ Audio saved: {filename}")
            print(f"   ⏱️  Duration: {duration:.2f} seconds")
        
        # Summary
        print("\n" + "=" * 60)
        print("🎉 AUDIO GENERATION COMPLETE!")
        print("=" * 60)
        print(f"📁 Output directory: {os.path.abspath(output_dir)}")
        print(f"📊 Generated {len(generated_files)} audio files:")
        print()
        
        for filename, bisaya, english, duration in generated_files:
            print(f"   🎵 {filename}")
            print(f"      Bisaya: {bisaya}")
            print(f"      English: {english}")
            print(f"      Duration: {duration:.2f}s")
            print()
        
        print("🔊 You can now play the generated .wav files to hear the Bisaya speech!")
        
        return True
        
    except ImportError as e:
        print(f"❌ Import Error: {e}")
        print("\n💡 Please install the required packages:")
        print("   pip install torch transformers scipy")
        return False
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_model_loading():
    """Test if the model can be loaded without generating audio"""
    print("🧪 Testing model loading...")
    
    try:
        model = VitsModel.from_pretrained("facebook/mms-tts-1b-all")
        tokenizer = AutoTokenizer.from_pretrained("facebook/mms-tts-1b-all")
        tokenizer.set_target_language("ceb")
        
        print("✅ Model loaded successfully!")
        print(f"📊 Sampling rate: {model.config.sampling_rate} Hz")
        print(f"🌍 Language set to: Cebuano (ceb)")
        
        # Test tokenization
        test_text = "Kumusta ka?"
        inputs = tokenizer(test_text, return_tensors="pt")
        print(f"📝 Tokenized '{test_text}': {inputs.input_ids.shape}")
        
        return True
        
    except Exception as e:
        print(f"❌ Model loading failed: {e}")
        return False

if __name__ == "__main__":
    print("🎤 Facebook MMS TTS - Bisaya (Cebuano) Demo")
    print("🌍 Language Code: ceb (ISO 639-3)")
    print("📦 Model: facebook/mms-tts-1b-all")
    print()
    
    # First test model loading
    if test_model_loading():
        print("\n" + "="*50)
        # If successful, generate audio
        generate_bisaya_audio()
    else:
        print("\n💡 Model loading failed. Please check your internet connection and dependencies.")
