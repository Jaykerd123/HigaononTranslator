import json
import tempfile
import unittest
from pathlib import Path

from translation_retrieval import ReferenceRetrievalIndex


class ReferenceRetrievalIndexTests(unittest.TestCase):
    def setUp(self) -> None:
        self.index = ReferenceRetrievalIndex(
            dictionary_entries=[
                {
                    "english": "house",
                    "higaonon": "balay",
                    "example_english": "Our house is large.",
                    "example_higaonon": "Dakula an balay nami.",
                },
            ],
            phrase_entries=[
                {
                    "example_english": "Good morning",
                    "example_higaonon": "Maayong buntag",
                },
                {
                    "example_english": "Good morning!",
                    "example_higaonon": "Maupay nga buntag",
                },
                {
                    "example_english": "We live near the river.",
                    "example_higaonon": "Nagpuyo kami duol sa sapa.",
                },
            ],
        )

    def test_exact_lookup_normalizes_case_and_punctuation(self) -> None:
        result = self.index.retrieve("  GOOD MORNING?! ")

        self.assertEqual(result["match_type"], "exact")
        self.assertEqual(result["candidate_count"], 2)
        self.assertEqual(
            [reference["higaonon"] for reference in result["references"]],
            ["Maayong buntag", "Maupay nga buntag"],
        )

    def test_exact_word_and_example_references_include_context(self) -> None:
        word_result = self.index.retrieve("HOUSE")
        example_result = self.index.retrieve("Our house is large")

        self.assertEqual(word_result["match_type"], "exact")
        self.assertEqual(word_result["references"][0]["kind"], "word")
        self.assertEqual(
            word_result["references"][0]["speaker_verification_status"],
            "unknown",
        )
        self.assertIn("context", word_result["references"][0])
        self.assertEqual(example_result["match_type"], "exact")
        self.assertEqual(
            example_result["references"][0]["kind"], "example_sentence"
        )

    def test_related_lookup_ranks_lexical_overlap(self) -> None:
        result = self.index.retrieve("We live by the river")

        self.assertEqual(result["match_type"], "related")
        self.assertGreater(result["candidate_count"], 0)
        self.assertEqual(
            result["references"][0]["english"], "We live near the river."
        )
        self.assertIn("relevance_score", result["references"][0])

    def test_unmatched_query_returns_no_candidates(self) -> None:
        result = self.index.retrieve("unrelated vocabulary")

        self.assertEqual(result["match_type"], "none")
        self.assertEqual(result["candidate_count"], 0)
        self.assertEqual(result["references"], [])

    def test_stopword_only_query_does_not_return_unrelated_entries(self) -> None:
        result = self.index.retrieve("the")

        self.assertEqual(result["match_type"], "none")
        self.assertEqual(result["candidate_count"], 0)

    def test_rejects_empty_query_and_invalid_limit(self) -> None:
        with self.assertRaisesRegex(ValueError, "cannot be empty"):
            self.index.retrieve("  ")
        with self.assertRaisesRegex(ValueError, "greater than zero"):
            self.index.retrieve("house", limit=0)

    def test_reads_bundled_json_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            dictionary_path = Path(temporary_directory) / "dictionary.json"
            phrase_path = Path(temporary_directory) / "dictionary-second.json"
            dictionary_path.write_text(
                json.dumps(
                    [
                        {
                            "english": "house",
                            "higaonon": "balay",
                            "example_english": "A small house",
                            "example_higaonon": "Gam-ay nga balay",
                        }
                    ]
                ),
                encoding="utf-8",
            )
            phrase_path.write_text(
                json.dumps(
                    [
                        {
                            "example_english": "Where are you?",
                            "example_higaonon": "Hindu ka",
                        }
                    ]
                ),
                encoding="utf-8",
            )

            index = ReferenceRetrievalIndex.from_json_files(
                dictionary_path, phrase_path
            )

        self.assertEqual(index.reference_count, 3)
        self.assertEqual(index.retrieve("house")["match_type"], "exact")

    def test_reads_utf8_bom_csv_and_preserves_duplicate_translations(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            dictionary_path = Path(temporary_directory) / "dictionary.json"
            phrase_path = Path(temporary_directory) / "dictionary-second.json"
            csv_path = Path(temporary_directory) / "cleaned_dataset.csv"
            dictionary_path.write_text("[]", encoding="utf-8")
            phrase_path.write_text("[]", encoding="utf-8")
            csv_path.write_text(
                "\ufeffenglish,higaonon\nbring,daladala\nbring,kuha\n",
                encoding="utf-8",
                newline="",
            )

            index = ReferenceRetrievalIndex.from_files(
                dictionary_path, phrase_path, csv_path
            )
            result = index.retrieve("BRING!")

        self.assertEqual(result["match_type"], "exact")
        self.assertEqual(result["candidate_count"], 2)
        self.assertEqual(
            [reference["higaonon"] for reference in result["references"]],
            ["daladala", "kuha"],
        )
        self.assertEqual(
            [reference["id"] for reference in result["references"]],
            ["cleaned_dataset.csv:1", "cleaned_dataset.csv:2"],
        )
        self.assertTrue(
            all(
                reference["source_file"] == "cleaned_dataset.csv"
                for reference in result["references"]
            )
        )
        self.assertTrue(
            all(
                reference["speaker_verification_status"] == "unknown"
                for reference in result["references"]
            )
        )

    def test_related_lookup_includes_csv_references(self) -> None:
        index = ReferenceRetrievalIndex(
            dictionary_entries=[],
            phrase_entries=[],
            csv_entries=[
                {"english": "a small house", "higaonon": "gam-ay nga balay"},
                {"english": "the river is wide", "higaonon": "lapad an sapa"},
            ],
        )

        result = index.retrieve("small home")

        self.assertEqual(result["match_type"], "related")
        self.assertEqual(
            result["references"][0]["source_file"], "cleaned_dataset.csv"
        )
        self.assertEqual(result["references"][0]["english"], "a small house")

    def test_csv_requires_expected_column_names(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            csv_path = Path(temporary_directory) / "invalid.csv"
            csv_path.write_text(
                "source,target\nhello,higaonon\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "english.*higaonon"):
                ReferenceRetrievalIndex._read_csv_entries(csv_path)


if __name__ == "__main__":
    unittest.main()
