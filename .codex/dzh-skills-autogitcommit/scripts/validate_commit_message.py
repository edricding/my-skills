#!/usr/bin/env python3
"""Validate commit title/body layout and line lengths."""

from __future__ import annotations

import argparse
import pathlib
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate commit message title/body against common limits."
    )
    parser.add_argument("--title", help="Commit title (single line).")
    parser.add_argument("--body", default="", help="Commit body text.")
    parser.add_argument(
        "--message-file",
        help="Path to a full commit message file (title on first line).",
    )
    parser.add_argument(
        "--title-max",
        type=int,
        default=72,
        help="Maximum title length (default: 72).",
    )
    parser.add_argument(
        "--body-line-max",
        type=int,
        default=72,
        help="Maximum body line length (default: 72).",
    )
    return parser.parse_args()


def parse_from_file(path: pathlib.Path) -> tuple[str, str, bool]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    if not lines:
        return "", "", False

    title = lines[0]
    if len(lines) == 1:
        return title, "", False

    has_separator = lines[1] == ""
    if has_separator:
        body = "\n".join(lines[2:])
    else:
        body = "\n".join(lines[1:])
    return title, body, has_separator


def validate(
    title: str,
    body: str,
    has_separator: bool,
    title_max: int,
    body_line_max: int,
) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    if not title.strip():
        errors.append("Title is empty.")
    if "\n" in title:
        errors.append("Title must be a single line.")
    if len(title) > title_max:
        errors.append(f"Title is {len(title)} chars (max {title_max}).")

    if title.endswith("."):
        warnings.append("Title ends with a period; prefer no trailing punctuation.")

    body_lines = body.splitlines()
    if body_lines and not has_separator:
        errors.append("Body must be separated from title by one blank line.")

    for idx, line in enumerate(body_lines, start=1):
        if len(line) > body_line_max and not line.startswith(("http://", "https://")):
            errors.append(
                f"Body line {idx} is {len(line)} chars (max {body_line_max})."
            )
        if line.rstrip() != line:
            warnings.append(f"Body line {idx} has trailing whitespace.")

    return errors, warnings


def main() -> int:
    args = parse_args()

    if args.message_file:
        title, body, has_separator = parse_from_file(pathlib.Path(args.message_file))
    else:
        if args.title is None:
            print("ERROR: Provide --title when --message-file is not used.", file=sys.stderr)
            return 2
        title = args.title
        body = args.body
        # Separator validation applies only when parsing a full message file.
        has_separator = True

    errors, warnings = validate(
        title=title,
        body=body,
        has_separator=has_separator,
        title_max=args.title_max,
        body_line_max=args.body_line_max,
    )

    print(f"title_length={len(title)} (max={args.title_max})")
    print(f"body_lines={len(body.splitlines())} (line_max={args.body_line_max})")

    if warnings:
        print("warnings:")
        for warning in warnings:
            print(f"- {warning}")

    if errors:
        print("result=FAIL")
        print("errors:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("result=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
