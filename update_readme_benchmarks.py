#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from collections import OrderedDict
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class SectionConfig:
    title: str
    columns: tuple[str, ...]
    headers: tuple[str, ...]


SECTION_CONFIGS: tuple[SectionConfig, ...] = (
    SectionConfig(
        title="Interpreted",
        columns=(
            "DAS INTERPRETER",
            "LUAU",
            "LUA",
            "LUAJIT -joff",
            "QUIRREL",
            "QUICKJS",
            "MONO --interpreter",
        ),
        headers=(
            "DAS interpreter",
            "Luau",
            "Lua",
            "LuaJIT -joff",
            "Quirrel",
            "QuickJS",
            "Mono --interpreter",
        ),
    ),
    SectionConfig(
        title="AOT or JIT",
        columns=(
            "DAS AOT",
            "DAS JIT",
            "C++",
            "LUAU --codegen",
            "LUAJIT",
            "MONO",
            ".NET",
        ),
        headers=(
            "DAS AOT",
            "DAS JIT",
            "C++",
            "Luau --codegen",
            "LuaJIT",
            "Mono",
            ".NET",
        ),
    ),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Regenerate the benchmark snapshot tables in README.md from a benchmark JSON file."
    )
    parser.add_argument(
        "history_json",
        nargs="?",
        default="profile_results.json",
        help="Path to the benchmark JSON file.",
    )
    parser.add_argument(
        "--readme",
        default="README.md",
        help="Path to the README file to update.",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Print the generated benchmark snapshot instead of updating the README.",
    )
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle, object_pairs_hook=OrderedDict)
    if not isinstance(data, dict):
        raise ValueError(f"Top-level JSON value must be an object: {path}")
    return data


def build_snapshot(data: dict[str, Any], history_path: Path, readme_path: Path) -> str:
    cpu = require_string(data, "cpu")
    timestamp = require_string(data, "timestamp")
    versions = require_object(data, "versions")
    rel_history_path = relative_display_path(history_path, readme_path.parent)

    lines = [
        "## Benchmark Snapshot",
        "",
        "Platform information:",
        "",
        f"- {platform_name()} on {cpu}",
        f"- Captured from `{rel_history_path}` on {timestamp}",
        (
            f"- Toolchain: {require_string(versions, 'cpp_compiler')}, "
            f"daslang {require_string(versions, 'daslang')}, "
            f"LLVM {require_string(versions, 'llvm')}"
        ),
        (
            f"- Runtimes: {format_runtime_version('lua', require_string(versions, 'lua'))}, "
            f"{format_runtime_version('luajit', require_string(versions, 'luajit'))}, "
            f"{format_runtime_version('luau', require_string(versions, 'luau'))}, "
            f"{format_runtime_version('mono', require_string(versions, 'mono'))}, "
            f"{format_runtime_version('dotnet', require_string(versions, 'dotnet'))}, "
            f"{format_runtime_version('quickjs', require_string(versions, 'quickjs'))}, "
            f"{format_runtime_version('quirrel', require_string(versions, 'quirrel'))}"
        ),
        "",
        "Lower is better. The fastest result in each row is in bold. `-` means no value for that runtime on that benchmark.",
    ]

    for config in SECTION_CONFIGS:
        section = require_object(data, config.title)
        lines.extend(["", f"### {config.title}", ""])
        lines.extend(render_table(config, section))

    return "\n".join(lines)


def render_table(config: SectionConfig, section: dict[str, Any]) -> list[str]:
    lines = [
        "| Test | " + " | ".join(config.headers) + " |",
        "| --- | " + " | ".join("---:" for _ in config.headers) + " |",
    ]

    expected_languages = set(config.columns)
    for test_name, row in section.items():
        if not isinstance(test_name, str):
            raise ValueError(f"Benchmark name must be a string in section {config.title!r}")
        entries = validate_row(config.title, test_name, row)
        row_languages = set(entries)
        unknown = sorted(row_languages - expected_languages)
        if unknown:
            raise ValueError(
                f"Unexpected language(s) in {config.title!r}/{test_name!r}: {', '.join(unknown)}"
            )
        best_time = min(entry["time"] for entry in entries.values())
        values = [format_cell(entries.get(language), best_time) for language in config.columns]
        lines.append(f"| {test_name} | " + " | ".join(values) + " |")

    return lines


def validate_row(section_name: str, test_name: str, row: Any) -> dict[str, dict[str, Any]]:
    if not isinstance(row, list) or not row:
        raise ValueError(f"Section {section_name!r}, row {test_name!r} must be a non-empty array")
    entries: dict[str, dict[str, Any]] = {}
    for item in row:
        if not isinstance(item, dict):
            raise ValueError(f"Section {section_name!r}, row {test_name!r} has a non-object entry")
        language = require_string(item, "language")
        if language in entries:
            raise ValueError(
                f"Duplicate language {language!r} in section {section_name!r}, row {test_name!r}"
            )
        time = item.get("time")
        count = item.get("count")
        if not isinstance(time, (int, float)):
            raise ValueError(
                f"Section {section_name!r}, row {test_name!r}, language {language!r} has invalid time"
            )
        if not isinstance(count, int):
            raise ValueError(
                f"Section {section_name!r}, row {test_name!r}, language {language!r} has invalid count"
            )
        entries[language] = {"time": float(time), "count": count}
    return entries


def format_cell(entry: dict[str, Any] | None, best_time: float) -> str:
    if entry is None:
        return "-"
    value = f"{entry['time']:.6f}s"
    if abs(entry["time"] - best_time) <= 1e-12:
        return f"**{value}**"
    return value


def relative_display_path(path: Path, base_dir: Path) -> str:
    try:
        return path.resolve().relative_to(base_dir.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def require_object(data: dict[str, Any], key: str) -> dict[str, Any]:
    value = data.get(key)
    if not isinstance(value, dict):
        raise ValueError(f"Expected object at key {key!r}")
    return value


def require_string(data: dict[str, Any], key: str) -> str:
    value = data.get(key)
    if not isinstance(value, str) or not value:
        raise ValueError(f"Expected non-empty string at key {key!r}")
    return value


def short_version(text: str) -> str:
    return text.strip().splitlines()[0]


def format_runtime_version(name: str, text: str) -> str:
    line = short_version(text)
    if name == "lua":
        return line.split("  Copyright", 1)[0]
    if name == "luajit":
        return line.split(" -- ", 1)[0]
    if name == "luau":
        return f"Luau {line}" if not line.startswith("Luau ") else line
    if name == "mono":
        marker = "version "
        if marker in line:
            return f"Mono {line.split(marker, 1)[1]}"
        return line
    if name == "dotnet":
        return f".NET {line}" if not line.startswith(".NET ") else line
    if name == "quickjs":
        marker = "version "
        if marker in line:
            return f"QuickJS {line.split(marker, 1)[1]}"
        return line
    if name == "quirrel":
        return f"Quirrel {line.split(' Copyright', 1)[0]}"
    return line


def platform_name() -> str:
    import platform

    system = platform.system().lower()
    if system == "darwin":
        return "macOS"
    if system == "windows":
        return "Windows"
    if system == "linux":
        return "Linux"
    return platform.system()


def update_readme(readme_path: Path, snapshot: str) -> None:
    original = readme_path.read_text(encoding="utf-8")
    start = original.find("## Benchmark Snapshot")
    related = original.find("## Related")
    if related == -1:
        raise ValueError(f"Could not find '## Related' in {readme_path}")

    if start == -1:
        insertion = "\n\n" + snapshot + "\n\n"
        updated = original[:related] + insertion + original[related:]
    else:
        prefix = original[:start].rstrip() + "\n\n"
        suffix = original[related:].lstrip()
        updated = prefix + snapshot + "\n\n" + suffix

    readme_path.write_text(updated, encoding="utf-8")


def main() -> int:
    args = parse_args()
    readme_path = Path(args.readme).resolve()
    history_path = Path(args.history_json).resolve()
    data = load_json(history_path)
    snapshot = build_snapshot(data, history_path, readme_path)
    if args.stdout:
        print(snapshot)
        return 0
    update_readme(readme_path, snapshot)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())