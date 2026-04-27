#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 3 ]]; then
  echo "Usage: $0 <input_log> [-o <output_md>]" >&2
  exit 2
fi

input_log="$1"
output_path=""

if [[ $# -ge 2 ]]; then
  if [[ "$2" != "-o" && "$2" != "--output" ]]; then
    echo "Usage: $0 <input_log> [-o <output_md>]" >&2
    exit 2
  fi
  if [[ $# -ne 3 ]]; then
    echo "Missing output path for $2" >&2
    exit 2
  fi
  output_path="$3"
fi

python3 - "$input_log" "$output_path" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional


def reorder_fields(value: Any) -> Any:
    if isinstance(value, dict):
        reordered: Dict[str, Any] = {}
        for key, subval in value.items():
            if key not in ("old_string", "new_string"):
                reordered[key] = reorder_fields(subval)
        if "old_string" in value:
            reordered["old_string"] = reorder_fields(value["old_string"])
        if "new_string" in value:
            reordered["new_string"] = reorder_fields(value["new_string"])
        return reordered
    if isinstance(value, list):
        return [reorder_fields(item) for item in value]
    return value


def flush_buffer(lines: List[str], chunks: List[str]) -> None:
    if not chunks:
        return
    text = "".join(chunks).strip()
    if not text:
        chunks.clear()
        return
    lines.append(text)
    lines.append("")
    chunks.clear()


def format_triple_quoted_field(key_text: str, value: str, indent: int) -> str:
    pad = " " * indent
    return f'{pad}{key_text}:\n{pad}"""\n{value}\n{pad}"""'


def dumps_with_triple_quotes(value: Any, indent: int = 0) -> str:
    pad = " " * indent
    if isinstance(value, dict):
        if not value:
            return "{}"
        lines: List[str] = ["{"]
        items = list(value.items())
        for idx, (key, subval) in enumerate(items):
            key_text = json.dumps(key, ensure_ascii=True)
            is_last = idx == len(items) - 1
            if key in ("old_string", "new_string") and isinstance(subval, str):
                block = format_triple_quoted_field(key_text, subval, indent + 2)
                if not is_last:
                    block += ","
                lines.append(block)
            else:
                subtext = dumps_with_triple_quotes(subval, indent + 2)
                entry = f'{" " * (indent + 2)}{key_text}: {subtext}'
                if not is_last:
                    entry += ","
                lines.append(entry)
        lines.append(f"{pad}}}")
        return "\n".join(lines)
    if isinstance(value, list):
        if not value:
            return "[]"
        lines = ["["]
        for idx, item in enumerate(value):
            item_text = dumps_with_triple_quotes(item, indent + 2)
            line = f'{" " * (indent + 2)}{item_text}'
            if idx != len(value) - 1:
                line += ","
            lines.append(line)
        lines.append(f"{pad}]")
        return "\n".join(lines)
    return json.dumps(value, ensure_ascii=True)


def format_tool_use(record: Dict[str, Any]) -> str:
    payload = reorder_fields(
        {
            "tool_name": record.get("tool_name"),
            "parameters": record.get("parameters", {}),
        }
    )
    formatted = dumps_with_triple_quotes(payload, indent=0)
    return "```json\n" + formatted + "\n```"


def parse_log_to_markdown(input_path: Path) -> str:
    prompt_path = input_path.with_suffix(".prompt.txt")
    meta_path = input_path.with_suffix(".meta")
    out_lines: List[str] = [
        f"# Parsed Messages from `{input_path.name}`",
        "",
    ]

    if prompt_path.exists():
        prompt_text = prompt_path.read_text(encoding="utf-8").rstrip()
        out_lines.extend(
            [
                "## Prompt",
                "",
                "```text",
                prompt_text,
                "```",
                "",
            ]
        )

    if meta_path.exists():
        meta_text = meta_path.read_text(encoding="utf-8").rstrip()
        out_lines.extend(
            [
                "## Meta",
                "",
                "```text",
                meta_text,
                "```",
                "",
            ]
        )

    out_lines.extend(
        [
            "## Transcript",
            "",
        ]
    )

    current_role: Optional[str] = None
    current_chunks: List[str] = []

    for raw_line in input_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or not line.startswith("{"):
            continue

        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            continue

        rtype = record.get("type")

        if rtype == "message":
            role = record.get("role", "unknown")
            content = record.get("content", "")
            delta = bool(record.get("delta", False))

            if delta:
                if current_role is None:
                    current_role = role
                if role != current_role:
                    flush_buffer(out_lines, current_chunks)
                    current_role = role
                current_chunks.append(content)
                continue

            flush_buffer(out_lines, current_chunks)
            current_role = None
            text = str(content).strip()
            if text:
                out_lines.append(text)
                out_lines.append("")
            continue

        if rtype == "tool_use":
            flush_buffer(out_lines, current_chunks)
            current_role = None
            out_lines.append(format_tool_use(record))
            out_lines.append("")
            continue

    flush_buffer(out_lines, current_chunks)
    return "\n".join(out_lines).rstrip() + "\n"


def main() -> None:
    input_path = Path(sys.argv[1])
    if not input_path.exists():
        raise FileNotFoundError(f"Input file does not exist: {input_path}")

    output_arg = sys.argv[2] if len(sys.argv) > 2 else ""
    output_path = Path(output_arg) if output_arg else input_path.with_suffix(".md")
    markdown = parse_log_to_markdown(input_path)
    output_path.write_text(markdown, encoding="utf-8")
    print(f"Wrote markdown to: {output_path}")


if __name__ == "__main__":
    main()
PY
