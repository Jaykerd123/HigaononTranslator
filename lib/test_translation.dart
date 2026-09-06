
import 'package:Higa/screens/services/onnx_translation_service.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

final translator = OnnxTranslationService();

// ============================================================
// TEST SENTENCES
// ============================================================

final tests = [
"I am here.",
"Where are you going.",
"Hello, how are you?",
"What is your name?",
"Thank you very much.",
"I love you.",
"Good morning.",
"Good afternoon.",
"Good evening.",
"Good night.",
"How are you?",
"I am fine.",
"I am hungry.",
"I am thirsty.",
"I am tired.",
"Please help me.",
"Come here.",
"Go there.",
"Wait for me.",
"What are you doing?",
"Where are you?",
"Who are you?",
"What happened?",
"I don't know.",
"I understand.",
"I don't understand.",
"Let's go home.",
"I am going home.",
"Where is your house?",
"This is my house.",
"That is my friend.",
"He is my brother.",
"She is my sister.",
"My mother is here.",
"My father is at home.",
"The children are playing.",
"The sun is shining.",
"It is raining today.",
"The weather is good.",
"I want to eat.",
"I want to drink water.",
"Can you help me?",
"Can you hear me?",
"Please wait here.",
"I will come back tomorrow.",
"I went there yesterday.",
"We are going together.",
"They are waiting outside.",
"What time is it?",
"Where are we going?",
];

// ============================================================
// RUN TESTS
// ============================================================

print("");
print("=" * 70);
print("HIGAONON FLUTTER ONNX TRANSLATION TEST");
print("=" * 70);

for (int i = 0; i < tests.length; i++) {
final text = tests[i];

print("");
print("TEST ${i + 1}/${tests.length}");
print("INPUT: $text");

try {
final result = await translator.translate(text);

print("RESULT: $result");
} catch (e) {
print("ERROR: $e");
}

print("-" * 70);
}

print("");
print("=" * 70);
print("TEST COMPLETE");
print("=" * 70);

translator.dispose();
}
