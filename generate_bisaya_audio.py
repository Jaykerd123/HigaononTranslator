#!/usr/bin/env python3
"""
Generate Bisaya audio using Facebook MMS TTS model
"""

import torch
from transformers import VitsModel, AutoTokenizer
import scipy.io.wavfile
import os

def generate_bisaya_audio():
    print("Loading Facebook MMS TTS multilingual model...")
    
    try:
        # Load the multilingual model
        model = VitsModel.from_pretrained("facebook/mms-tts-1b-all")
        tokenizer = AutoTokenizer.from_pretrained("facebook/mms-tts-1b-all")
        
        print("✓ Model loaded successfully")
        print(f"Model sampling rate: {model.config.sampling_rate} Hz")
        
        # Set language to Cebuano (Bisaya)
        print("\nSetting language to Cebuano (Bisaya)...")
        tokenizer.set_target_language("ceb")
        print("✓ Language set to 'ceb' (Cebuano)")
        
        # Bisaya test phrases
        bisaya_phrases = [
            "Kumusta ka?",  # How are you?
            "Maayong adlaw.",  # Good day
            "Salamat kaayo.",  # Thank you very much
            "Unsa imong ngalan?",  # What is your name?
            "Nalingaw ko sa pagpangita sa imo."  # I was happy looking for you
        ]
        
        print(f"\nGenerating audio for {len(bisaya_phrases)} Bisaya phrases...")
        
        # Create output directory
        output_dir = "bisaya_audio_output"
        os.makedirs(output_dir, exist_ok=True)
        
        for i, phrase in enumerate(bisaya_phrases):
            print(f"\nProcessing phrase {i+1}: '{phrase}'")
            
            # Tokenize the text
            inputs = tokenizer(phrase, return_tensors="pt")
            
            # Generate audio
            with torch.no_grad():
                output = model(**inputs).waveform
            
            # Convert to numpy array
            audio_array = output.numpy().flatten()
            
            # Save as WAV file
            filename = f"bisaya_phrase_{i+1:02d}.wav"
            filepath = os.path.join(output_dir, filename)
            
            scipy.io.wavfile.write(
                filepath, 
                rate=model.config.sampling_rate, 
                data=audio_array
            )
            
            print(f"✓ Audio saved to: {filepath}")
            print(f"  Duration: {len(audio_array) / model.config.sampling_rate:.2f} seconds")
        
        print(f"\n" + "="*50)
        print("AUDIO GENERATION COMPLETE")
        print("="*50)
        print(f"Generated {len(bisaya_phrases)} audio files in '{output_dir}' directory:")
        
        for i, phrase in enumerate(bisaya_phrases):
            filename = f"bisaya_phrase_{i+1:02d}.wav"
            print(f"  {filename} - '{phrase}'")
        
        print(f"\nAll files saved in: {os.path.abspath(output_dir)}")
        
        return True
        
    except Exception as e:
        print(f"Error generating audio: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = generate_bisaya_audio()
    if success:
        print("\n✅ Bisaya audio generation completed successfully!")
    else:
        print("\n❌ Failed to generate Bisaya audio")
