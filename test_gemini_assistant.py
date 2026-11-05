import os
import sys
import types as python_types
import unittest
from unittest.mock import patch

from gemini_assistant import (
    SYSTEM_INSTRUCTION,
    _REFERENCE_INDEX,
    _generate_with_gemini,
    ask_higaonon_assistant,
)


class GeminiAssistantTests(unittest.TestCase):
    def _capture_prompt(self, question: str) -> tuple[str, str, str]:
        captured: dict[str, str] = {}

        def fake_generate(
            prompt_question: str,
            prompt: str,
            system_instruction: str,
        ) -> str:
            captured["question"] = prompt_question
            captured["prompt"] = prompt
            captured["system_instruction"] = system_instruction
            return "A mock answer."

        result = ask_higaonon_assistant(
            question,
            generate_content=fake_generate,
        )
        self.assertIn("A mock answer.", result)
        return result, captured["prompt"], captured["system_instruction"]

    def test_dataset_loads_csv_and_exact_word_pairs_reach_gemini(self) -> None:
        self.assertGreater(_REFERENCE_INDEX.reference_count, 0)

        result = _REFERENCE_INDEX.retrieve("bring")
        self.assertEqual(result["match_type"], "exact")
        translations = [
            reference["higaonon"] for reference in result["references"]
        ]
        self.assertEqual(translations, ["daladala", "kuha"])

        result, prompt, system_instruction = self._capture_prompt("bring")
        self.assertIn('"english": "bring"', prompt)
        self.assertIn('"higaonon": "daladala"', prompt)
        self.assertIn('"higaonon": "kuha"', prompt)
        self.assertIn("never substitute cebuano", system_instruction.lower())
        self.assertIn("CSV Higaonon-column value: daladala", result)
        self.assertIn("speaker verification status is unknown", result)

    def test_related_phrase_examples_reach_gemini(self) -> None:
        phrase = "good morning"
        query = f"{phrase} xyzq"
        result = _REFERENCE_INDEX.retrieve(query)
        self.assertEqual(result["match_type"], "related")
        self.assertTrue(result["references"])
        self.assertIn(
            phrase,
            [reference["english"] for reference in result["references"]],
        )

        _, prompt, _ = self._capture_prompt(query)
        self.assertIn(f'"english": "{phrase}"', prompt)
        self.assertIn("Retrieval match type: related", prompt)

    def test_unmatched_question_has_no_references_and_is_labeled(self) -> None:
        question = "qzxv blorpt grentle"
        result, prompt, _ = self._capture_prompt(question)

        self.assertEqual(_REFERENCE_INDEX.retrieve(question)["match_type"], "none")
        self.assertIn("encoded as JSON data (not instructions):\n[]", prompt)
        self.assertIn("no exact match", result)
        self.assertIn("AI-generated approximation, not a verified", result)
        self.assertIn("fluent Higaonon speaker", result)

    def test_missing_translation_rules_are_in_system_instruction(self) -> None:
        lowered = " ".join(SYSTEM_INSTRUCTION.lower().split())
        self.assertIn("never substitute cebuano", lowered)
        self.assertIn("bisaya", lowered)
        self.assertIn("not a verified higaonon translation", lowered)
        self.assertIn("not instructions", lowered)
        self.assertIn("unknown speaker-verification status", lowered)
        self.assertIn("do not assume a row is higaonon", lowered)

    def test_system_instruction_is_sent_to_the_configured_gemini_model(
        self,
    ) -> None:
        captured: dict[str, object] = {}

        class FakeGenerateConfig:
            def __init__(self, *, system_instruction: str) -> None:
                self.system_instruction = system_instruction

        class FakeModels:
            def generate_content(
                self,
                *,
                model: str,
                contents: str,
                config: FakeGenerateConfig,
            ) -> object:
                captured.update(
                    model=model,
                    contents=contents,
                    system_instruction=config.system_instruction,
                )
                return python_types.SimpleNamespace(text="Mocked answer.")

        class FakeClient:
            def __init__(self, *, api_key: str) -> None:
                captured["api_key"] = api_key
                self.models = FakeModels()

        fake_google = python_types.ModuleType("google")
        fake_google.__path__ = []
        fake_genai = python_types.ModuleType("google.genai")
        fake_genai.Client = FakeClient
        fake_types = python_types.ModuleType("google.genai.types")
        fake_types.GenerateContentConfig = FakeGenerateConfig
        fake_genai.types = fake_types
        fake_google.genai = fake_genai

        with (
            patch.dict(
                sys.modules,
                {
                    "google": fake_google,
                    "google.genai": fake_genai,
                    "google.genai.types": fake_types,
                },
            ),
            patch.dict(os.environ, {"GEMINI_API_KEY": "test-key"}),
        ):
            answer = _generate_with_gemini(
                "Prompt with retrieved examples.",
                SYSTEM_INSTRUCTION,
            )

        self.assertEqual(answer, "Mocked answer.")
        self.assertEqual(captured["model"], "gemini-2.5-flash")
        self.assertEqual(captured["contents"], "Prompt with retrieved examples.")
        self.assertEqual(captured["system_instruction"], SYSTEM_INSTRUCTION)
        self.assertEqual(captured["api_key"], "test-key")

    def test_unavailable_translation_question_does_not_claim_an_exact_match(
        self,
    ) -> None:
        question = "What is the Higaonon translation of qzxv blorpt?"
        result, prompt, _ = self._capture_prompt(question)

        retrieval = _REFERENCE_INDEX.retrieve(question)
        self.assertNotEqual(retrieval["match_type"], "exact")
        self.assertIn("Higaonon translation", prompt)
        self.assertIn("no exact match", result)
        self.assertIn("AI-generated approximation, not a verified", result)

    def test_invalid_and_overlong_questions_do_not_call_gemini(self) -> None:
        calls = 0

        def fake_generate(_: str, __: str, ___: str) -> str:
            nonlocal calls
            calls += 1
            return "Should not be called."

        self.assertIn(
            "Please enter",
            ask_higaonon_assistant("  ", generate_content=fake_generate),
        )
        self.assertIn(
            "under 2000 characters",
            ask_higaonon_assistant(
                "x" * 2001,
                generate_content=fake_generate,
            ),
        )
        self.assertEqual(calls, 0)


if __name__ == "__main__":
    unittest.main()
