#!/usr/bin/env python3
"""
Web-based Bisaya Audio Generation
This script uses web APIs to generate Bisaya audio when local dependencies aren't available.
"""

import requests
import json
import os
import base64

def generate_bisaya_audio_online():
    """Generate Bisaya audio using web-based TTS services"""
    
    print("🎤 Generating Bisaya Audio using Web Services")
    print("=" * 50)
    
    # Bisaya test phrases
    bisaya_phrases = [
        "Kumusta ka?",  # How are you?
        "Maayong adlaw.",  # Good day
        "Salamat kaayo.",  # Thank you very much
    ]
    
    print("📝 Bisaya phrases to generate:")
    for i, phrase in enumerate(bisaya_phrases, 1):
        print(f"   {i}. {phrase}")
    
    print("\n🌐 Attempting to generate audio using web services...")
    
    # Try different TTS approaches
    methods_tried = []
    
    # Method 1: Try to use a simple web-based approach
    try:
        print("\n🔍 Method 1: Checking for available web TTS services...")
        
        # Create a simple HTML file with JavaScript TTS
        html_content = f"""
<!DOCTYPE html>
<html lang="ceb">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bisaya TTS Audio Generator</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f0f8ff;
        }}
        .phrase {{
            background: white;
            padding: 15px;
            margin: 10px 0;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        button {{
            background: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            margin: 5px;
        }}
        button:hover {{
            background: #0056b3;
        }}
        .status {{
            color: #666;
            font-style: italic;
        }}
    </style>
</head>
<body>
    <h1>🎤 Bisaya (Cebuano) Text-to-Speech</h1>
    <p>Click the buttons below to hear Bisaya phrases spoken using your browser's built-in TTS.</p>
    
    {"".join([f'''
    <div class="phrase">
        <h3>Phrase {i+1}</h3>
        <p><strong>Bisaya:</strong> "{phrase}"</p>
        <button onclick="speakText('{phrase.replace("'", "\\'")}')">🔊 Play Audio</button>
        <span class="status" id="status{i+1}">Click to play</span>
    </div>
    ''' for i, phrase in enumerate(bisaya_phrases)])}
    
    <script>
        function speakText(text) {{
            if ('speechSynthesis' in window) {{
                // Cancel any ongoing speech
                window.speechSynthesis.cancel();
                
                // Create a new speech synthesis utterance
                const utterance = new SpeechSynthesisUtterance(text);
                
                // Prefer Filipino/Philippines voices (closest available to Bisaya).
                // Note: Browser voices depend on your OS and can change over time.
                utterance.lang = 'tl-PH'; // Filipino / Philippines
                utterance.rate = 0.9; // Slightly slower for clarity
                utterance.pitch = 0.95; // Slightly lower pitch (more "male"-like)
                utterance.volume = 1.0;
                
                // Find available voices
                const voices = window.speechSynthesis.getVoices();
                console.log('Available voices:', voices);
                
                // Heuristic: try to find a *male* Filipino/Philippines voice first
                const filipinoVoices = voices.filter(voice =>
                    (voice.lang && (voice.lang.toLowerCase().includes('tl') ||
                                    voice.lang.toLowerCase().includes('fil') ||
                                    voice.lang.toLowerCase().includes('ph'))) ||
                    (voice.name && /filipino|tagalog|philippines/i.test(voice.name))
                );
                
                const maleKeywords = ['male', 'man', 'guy', 'microsoft andro', 'andrew', 'enrique', 'james'];
                
                const maleFilipinoVoice = filipinoVoices.find(voice =>
                    maleKeywords.some(keyword => voice.name && voice.name.toLowerCase().includes(keyword))
                );
                
                // Fallbacks: Filipino voice (any gender) → any PH voice → default
                const anyFilipinoVoice = filipinoVoices[0];
                const anyPHVoice = voices.find(voice =>
                    voice.lang && voice.lang.toLowerCase().includes('ph')
                );
                
                if (maleFilipinoVoice) {{
                    utterance.voice = maleFilipinoVoice;
                    console.log('Using male Filipino voice:', maleFilipinoVoice.name);
                }} else if (anyFilipinoVoice) {{
                    utterance.voice = anyFilipinoVoice;
                    console.log('Using Filipino voice:', anyFilipinoVoice.name);
                }} else if (anyPHVoice) {{
                    utterance.voice = anyPHVoice;
                    console.log('Using Philippines voice:', anyPHVoice.name);
                }} else {{
                    console.log('Filipino/PH voice not found, using browser default voice');
                }}
                
                utterance.onstart = function() {{
                    console.log('Speaking:', text);
                }};
                
                utterance.onend = function() {{
                    console.log('Finished speaking:', text);
                }};
                
                utterance.onerror = function(event) {{
                    console.error('Speech error:', event.error);
                }};
                
                // Speak the text
                window.speechSynthesis.speak(utterance);
                
            }} else {{
                alert('Speech synthesis is not supported in your browser. Please try Chrome, Safari, or Edge.');
            }}
        }}
        
        // Load voices when available
        window.speechSynthesis.onvoiceschanged = function() {{
            console.log('Voices loaded:', window.speechSynthesis.getVoices().length);
        }};
        
        // Initial voice load
        window.speechSynthesis.getVoices();
    </script>
    
    <div style="margin-top: 30px; padding: 20px; background: #e7f3ff; border-radius: 8px;">
        <h2>📝 About This Demo</h2>
        <p>This uses your browser's built-in text-to-speech capability to generate Bisaya audio.</p>
        <p><strong>Note:</strong> Browser TTS may not have perfect Bisaya pronunciation, but it provides immediate audio feedback.</p>
        <p>For high-quality Bisaya audio, use the Facebook MMS TTS model with the code provided in the other scripts.</p>
    </div>
</body>
</html>
        """
        
        # Save the HTML file
        with open("bisaya_tts_browser_demo.html", "w", encoding="utf-8") as f:
            f.write(html_content)
        
        print("✅ Created browser-based TTS demo: bisaya_tts_browser_demo.html")
        print("🌐 Open this file in your web browser to hear Bisaya audio!")
        methods_tried.append("Browser TTS")
        
    except Exception as e:
        print(f"❌ Browser TTS creation failed: {e}")
    
    # Method 2: Try to create a simple audio file using basic Python
    try:
        print("\n🔍 Method 2: Creating simple audio demonstration...")
        
        # Create a simple WAV file with a tone (placeholder for actual TTS)
        import wave
        import struct
        
        def create_placeholder_wav(filename, duration=2.0, frequency=440):
            """Create a simple WAV file as a placeholder"""
            
            # WAV parameters
            sample_rate = 16000
            n_samples = int(duration * sample_rate)
            amplitude = 32767  # Max amplitude for 16-bit
            
            # Generate sine wave
            data = []
            for i in range(n_samples):
                value = int(amplitude * 0.5 * (i / n_samples))  # Fade in
                sample = int(value * 0.1 * (i % 100) / 100)  # Simple modulation
                data.append(struct.pack('<h', sample))
            
            # Create WAV file
            with wave.open(filename, 'w') as wav_file:
                wav_file.setnchannels(1)  # Mono
                wav_file.setsampwidth(2)  # 16-bit
                wav_file.setframerate(sample_rate)
                wav_file.writeframes(b''.join(data))
        
        # Create placeholder audio files
        os.makedirs("bisaya_audio_output", exist_ok=True)
        
        for i, phrase in enumerate(bisaya_phrases):
            filename = f"bisaya_audio_output/bisaya_placeholder_{i+1:02d}.wav"
            create_placeholder_wav(filename, duration=2.0)
            print(f"✅ Created placeholder: {filename}")
        
        print("📁 Placeholder audio files created in bisaya_audio_output/")
        methods_tried.append("Placeholder WAV")
        
    except Exception as e:
        print(f"❌ Placeholder creation failed: {e}")
    
    print(f"\n📊 Summary of methods attempted: {', '.join(methods_tried)}")
    
    print("\n🎯 Best Option for Immediate Audio:")
    print("1. Open 'bisaya_tts_browser_demo.html' in Chrome/Safari/Edge")
    print("2. Click the play buttons to hear Bisaya phrases")
    print("3. This uses your browser's built-in TTS (may not be perfect Bisaya)")
    
    print("\n🔧 For High-Quality Bisaya Audio:")
    print("1. Install: pip install torch transformers scipy")
    print("2. Run: python bisaya_tts_demo.py")
    print("3. This uses Facebook MMS TTS model with proper Bisaya pronunciation")
    
    return True

if __name__ == "__main__":
    generate_bisaya_audio_online()
