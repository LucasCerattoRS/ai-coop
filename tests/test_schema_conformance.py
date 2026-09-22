#!/usr/bin/env python3
"""Validate published coordination data with an independent JSON Schema engine."""
import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[1]


def check(paths, schema_path):
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    errors = []
    for path in paths:
        data = json.loads(path.read_text(encoding="utf-8"))
        for error in validator.iter_errors(data):
            where = "/".join(str(part) for part in error.path) or "<root>"
            errors.append(f"{path.relative_to(ROOT)}:{where}: {error.message}")
    if errors:
        raise AssertionError("\n".join(errors))


def main():
    check(
        sorted((ROOT / ".ai/examples").glob("*.json"))
        + sorted((ROOT / ".ai/handoffs").glob("**/*.json")),
        ROOT / ".ai/schemas/handoff.schema.json",
    )
    check(
        sorted((ROOT / ".ai/tasks").glob("*.json")),
        ROOT / ".ai/schemas/task.schema.json",
    )


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, json.JSONDecodeError) as exc:
        print(exc, file=sys.stderr)
        sys.exit(1)
