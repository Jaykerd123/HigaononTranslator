import csv
import json
import math
import re
import unicodedata
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Sequence


_TOKEN_PATTERN = re.compile(r"[^\W_]+", re.UNICODE)
_STOPWORDS = {
    "a",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "been",
    "being",
    "but",
    "by",
    "can",
    "could",
    "did",
    "do",
    "does",
    "for",
    "from",
    "had",
    "has",
    "have",
    "he",
    "her",
    "him",
    "his",
    "i",
    "if",
    "in",
    "is",
    "it",
    "its",
    "may",
    "me",
    "might",
    "must",
    "my",
    "of",
    "on",
    "or",
    "our",
    "she",
    "should",
    "so",
    "than",
    "that",
    "the",
    "their",
    "them",
    "they",
    "this",
    "those",
    "to",
    "us",
    "was",
    "we",
    "were",
    "will",
    "with",
    "would",
    "you",
    "your",
}


def _normalize(text: str) -> str:
    normalized = unicodedata.normalize("NFC", text).casefold()
    characters = [
        " " if unicodedata.category(char).startswith("P") else char
        for char in normalized
    ]
    return " ".join("".join(characters).split())


def _tokens(text: str) -> tuple[str, ...]:
    return tuple(_TOKEN_PATTERN.findall(_normalize(text)))


@dataclass(frozen=True)
class _Reference:
    reference_id: str
    source_file: str
    entry_index: int
    kind: str
    english: str
    higaonon: str
    context: dict[str, str] | None
    normalized_english: str
    tokens: tuple[str, ...]

    def as_dict(self, relevance_score: float | None = None) -> dict[str, object]:
        result: dict[str, object] = {
            "id": self.reference_id,
            "source_file": self.source_file,
            "entry_index": self.entry_index,
            "kind": self.kind,
            "english": self.english,
            "higaonon": self.higaonon,
            "speaker_verification_status": "unknown",
        }
        if self.context:
            result["context"] = self.context
        if relevance_score is not None:
            result["relevance_score"] = round(relevance_score, 6)
        return result


class ReferenceRetrievalIndex:
    """Exact-match-first lexical index over the bundled English-Higaonon data."""

    def __init__(
        self,
        dictionary_entries: Sequence[Mapping[str, object]],
        phrase_entries: Sequence[Mapping[str, object]],
        csv_entries: Sequence[Mapping[str, object]] = (),
    ) -> None:
        self._references: list[_Reference] = []
        self._exact_matches: dict[str, list[int]] = defaultdict(list)

        for entry_index, entry in enumerate(dictionary_entries, start=1):
            english = self._text(entry.get("english"))
            higaonon = self._text(entry.get("higaonon"))
            example_english = self._text(entry.get("example_english"))
            example_higaonon = self._text(entry.get("example_higaonon"))

            if english and higaonon:
                context = None
                if example_english and example_higaonon:
                    context = {
                        "english_example": example_english,
                        "higaonon_example": example_higaonon,
                    }
                self._add_reference(
                    reference_id=f"dictionary.json:{entry_index}:word",
                    source_file="dictionary.json",
                    entry_index=entry_index,
                    kind="word",
                    english=english,
                    higaonon=higaonon,
                    context=context,
                )

            if example_english and example_higaonon:
                context = None
                if english and higaonon:
                    context = {
                        "english_word": english,
                        "higaonon_word": higaonon,
                    }
                self._add_reference(
                    reference_id=f"dictionary.json:{entry_index}:example",
                    source_file="dictionary.json",
                    entry_index=entry_index,
                    kind="example_sentence",
                    english=example_english,
                    higaonon=example_higaonon,
                    context=context,
                )

        for entry_index, entry in enumerate(phrase_entries, start=1):
            english = self._text(entry.get("example_english"))
            higaonon = self._text(entry.get("example_higaonon"))
            if english and higaonon:
                self._add_reference(
                    reference_id=f"dictionary-second.json:{entry_index}",
                    source_file="dictionary-second.json",
                    entry_index=entry_index,
                    kind="phrase_or_sentence",
                    english=english,
                    higaonon=higaonon,
                )

        for entry_index, entry in enumerate(csv_entries, start=1):
            english = self._text(entry.get("english"))
            higaonon = self._text(entry.get("higaonon"))
            if english and higaonon:
                self._add_reference(
                    reference_id=f"cleaned_dataset.csv:{entry_index}",
                    source_file="cleaned_dataset.csv",
                    entry_index=entry_index,
                    kind="csv_reference",
                    english=english,
                    higaonon=higaonon,
                )

        self._document_frequencies: Counter[str] = Counter()
        self._postings: dict[str, list[tuple[int, int]]] = defaultdict(list)
        document_lengths: list[int] = []

        for reference_index, reference in enumerate(self._references):
            term_frequencies = Counter(reference.tokens)
            document_lengths.append(len(reference.tokens))
            for token, frequency in term_frequencies.items():
                self._document_frequencies[token] += 1
                self._postings[token].append((reference_index, frequency))

        self._average_document_length = (
            sum(document_lengths) / len(document_lengths) if document_lengths else 0
        )

    @classmethod
    def from_json_files(
        cls, dictionary_path: str | Path, phrase_path: str | Path
    ) -> "ReferenceRetrievalIndex":
        return cls.from_files(dictionary_path, phrase_path)

    @classmethod
    def from_files(
        cls,
        dictionary_path: str | Path,
        phrase_path: str | Path,
        csv_path: str | Path | None = None,
    ) -> "ReferenceRetrievalIndex":
        dictionary_entries = cls._read_entries(dictionary_path)
        phrase_entries = cls._read_entries(phrase_path)
        csv_entries = cls._read_csv_entries(csv_path) if csv_path is not None else []
        return cls(dictionary_entries, phrase_entries, csv_entries)

    @classmethod
    def from_csv_file(cls, csv_path: str | Path) -> "ReferenceRetrievalIndex":
        return cls([], [], cls._read_csv_entries(csv_path))

    @staticmethod
    def _read_entries(path: str | Path) -> list[Mapping[str, object]]:
        with Path(path).open(encoding="utf-8") as data_file:
            data = json.load(data_file)
        if not isinstance(data, list) or not all(
            isinstance(entry, dict) for entry in data
        ):
            raise ValueError(f"Expected a JSON array of objects in {path}.")
        return data

    @staticmethod
    def _read_csv_entries(path: str | Path) -> list[Mapping[str, object]]:
        with Path(path).open(encoding="utf-8-sig", newline="") as data_file:
            reader = csv.DictReader(data_file)
            fieldnames = reader.fieldnames or []
            if not {"english", "higaonon"}.issubset(fieldnames):
                raise ValueError(
                    f"Expected 'english' and 'higaonon' columns in {path}."
                )
            return list(reader)

    @staticmethod
    def _text(value: object) -> str:
        return value.strip() if isinstance(value, str) else ""

    @property
    def reference_count(self) -> int:
        return len(self._references)

    def _add_reference(
        self,
        *,
        reference_id: str,
        source_file: str,
        entry_index: int,
        kind: str,
        english: str,
        higaonon: str,
        context: dict[str, str] | None = None,
    ) -> None:
        normalized_english = _normalize(english)
        tokens = _tokens(english)
        if not normalized_english or not tokens:
            return

        reference_index = len(self._references)
        self._references.append(
            _Reference(
                reference_id=reference_id,
                source_file=source_file,
                entry_index=entry_index,
                kind=kind,
                english=english,
                higaonon=higaonon,
                context=context,
                normalized_english=normalized_english,
                tokens=tokens,
            )
        )
        self._exact_matches[normalized_english].append(reference_index)

    def retrieve(self, text: str, limit: int = 8) -> dict[str, object]:
        if not text.strip():
            raise ValueError("Text cannot be empty.")
        if limit < 1:
            raise ValueError("Limit must be greater than zero.")

        normalized_query = _normalize(text)
        exact_indices = self._exact_matches.get(normalized_query, [])
        if exact_indices:
            return {
                "query": text,
                "match_type": "exact",
                "candidate_count": len(exact_indices),
                "references": [
                    self._references[index].as_dict(relevance_score=1.0)
                    for index in exact_indices
                ],
            }

        query_tokens = tuple(
            token for token in _tokens(text) if token not in _STOPWORDS
        )
        if not query_tokens:
            return {
                "query": text,
                "match_type": "none",
                "candidate_count": 0,
                "references": [],
            }

        scores: dict[int, float] = defaultdict(float)
        total_documents = len(self._references)
        average_length = self._average_document_length or 1.0
        k1 = 1.5
        b = 0.75

        for token in set(query_tokens):
            postings = self._postings.get(token)
            if not postings:
                continue
            document_frequency = self._document_frequencies[token]
            inverse_document_frequency = math.log(
                1
                + (total_documents - document_frequency + 0.5)
                / (document_frequency + 0.5)
            )
            for reference_index, term_frequency in postings:
                document_length = len(self._references[reference_index].tokens)
                denominator = term_frequency + k1 * (
                    1 - b + b * document_length / average_length
                )
                scores[reference_index] += inverse_document_frequency * (
                    term_frequency * (k1 + 1) / denominator
                )

        if not scores:
            return {
                "query": text,
                "match_type": "none",
                "candidate_count": 0,
                "references": [],
            }

        ranked_indices = sorted(
            scores,
            key=lambda index: (-scores[index], self._references[index].reference_id),
        )
        return {
            "query": text,
            "match_type": "related",
            "candidate_count": len(ranked_indices),
            "references": [
                self._references[index].as_dict(scores[index])
                for index in ranked_indices[:limit]
            ],
        }
