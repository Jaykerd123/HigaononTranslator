from transformers import MarianMTModel, MarianTokenizer
import sys

def test_model(test_text):
    model_dir = "c:/HigaononTranslator/assets/nlp/model"
    
    try:
        print("Loading tokenizer setup...")
        tokenizer = MarianTokenizer.from_pretrained(model_dir)
        
        print("Loading model...")
        model = MarianMTModel.from_pretrained(model_dir)
        
        print(f"Testing translation for: '{test_text}'")
        inputs = tokenizer(test_text, return_tensors="pt", padding=True)
        
        print("Translating...")
        translated = model.generate(**inputs)
        result = tokenizer.batch_decode(translated, skip_special_tokens=True)
        
        print("\n--- TEST SUCCESSFUL ---")
        print("Original:", test_text)
        print("Translation:", result[0])
        print("-----------------------\n")
    except Exception as e:
        print(f"Error testing model: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        test_text = sys.argv[1]
    else:
        test_text = "Hello, how are you?"
        
    test_model(test_text)
