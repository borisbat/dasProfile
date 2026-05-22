#!/usr/bin/env python3
"""Regenerate the per-platform benchmark snapshot in README.md from
`profile_results_<platform>.json` files.

Each `profile_results_<platform>.json` becomes a `### <PlatformDisplayName>`
section with full prelude (CPU, capture path + timestamp, toolchain, runtime
versions) and the two benchmark tables (Interpreted / AOT or JIT). Sections
are ordered darwin first, then alphabetical by platform key. Platforms missing
a runtime show `-` in that column; rows with no entries are skipped.
"""

from __future__ import annotations

import argparse
import json
from collections import OrderedDict
from dataclasses import dataclass
from pathlib import Path
from typing import Any

PROFILE_GLOB = "profile_results_*.json"

# darwin first (canonical reference), then alpha. Unknown platforms sort last
# by name.
PLATFORM_DISPLAY = {"darwin": "macOS", "linux": "Linux", "windows": "Windows"}
PLATFORM_ORDER   = {"darwin": 0, "linux": 1, "windows": 2}


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
        description="Regenerate the per-platform benchmark snapshot in README.md."
    )
    parser.add_argument(
        "--profiles-dir",
        default=".",
        help="Directory holding profile_results_<platform>.json files (default: cwd).",
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


def find_profiles(profiles_dir: Path) -> list[tuple[Path, dict[str, Any]]]:
    paths = sorted(profiles_dir.glob(PROFILE_GLOB))
    profiles: list[tuple[Path, dict[str, Any]]] = []
    for p in paths:
        data = load_json(p)
        # Tolerate older files lacking the "platform" field by inferring from
        # the filename suffix. The new main.das always writes the field.
        if "platform" not in data:
            suffix = p.stem[len("profile_results_"):] if p.stem.startswith("profile_results_") else ""
            data["platform"] = suffix or "unknown"
        profiles.append((p, data))
    profiles.sort(key=lambda pair: (PLATFORM_ORDER.get(pair[1]["platform"], 99), pair[1]["platform"]))
    return profiles


def build_snapshot(profiles: list[tuple[Path, dict[str, Any]]], readme_path: Path) -> str:
    if not profiles:
        return ("## Benchmark Snapshot\n\n"
                "No `profile_results_<platform>.json` files found. Run `daslang main.das -- --json` "
                "on each target platform to capture data.\n")

    lines = ["## Benchmark Snapshot",
             "",
             "Per-platform captures. Lower is better. The fastest result in each row is in bold. "
             "`-` means no value for that runtime on that benchmark."]

    for path, data in profiles:
        lines.append("")
        lines.extend(render_platform_section(path, data, readme_path))

    return "\n".join(lines)


def render_platform_section(path: Path, data: dict[str, Any], readme_path: Path) -> list[str]:
    cpu = require_string(data, "cpu")
    platform_key = require_string(data, "platform")
    timestamp = require_string(data, "timestamp")
    versions = require_object(data, "versions")
    rel_path = relative_display_path(path, readme_path.parent)
    display = PLATFORM_DISPLAY.get(platform_key, platform_key.capitalize())

    lines = [
        f"### {display} — {cpu}",
        "",
        "Platform information:",
        "",
        f"- Captured from `{rel_path}` on {timestamp}",
        (
            f"- Toolchain: {require_string(versions, 'cpp_compiler')}, "
            f"daslang {require_string(versions, 'daslang')}, "
            f"LLVM {require_string(versions, 'llvm')}"
        ),
        (
            f"- Runtimes: {format_runtime_version('lua', optional_string(versions, 'lua'))}, "
            f"{format_runtime_version('luajit', optional_string(versions, 'luajit'))}, "
            f"{format_runtime_version('luau', optional_string(versions, 'luau'))}, "
            f"{format_runtime_version('mono', optional_string(versions, 'mono'))}, "
            f"{format_runtime_version('dotnet', optional_string(versions, 'dotnet'))}, "
            f"{format_runtime_version('quickjs', optional_string(versions, 'quickjs'))}, "
            f"{format_runtime_version('quirrel', optional_string(versions, 'quirrel'))}"
        ),
    ]

    for config in SECTION_CONFIGS:
        section = require_object(data, config.title)
        lines.extend(["", f"#### {config.title}", ""])
        lines.extend(render_table(config, section))

    return lines


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
        if not entries:
            continue
        best_time = min(entry["time"] for entry in entries.values())
        values = [format_cell(entries.get(language), best_time) for language in config.columns]
        lines.append(f"| {test_name} | " + " | ".join(values) + " |")

    return lines


def validate_row(section_name: str, test_name: str, row: Any) -> dict[str, dict[str, Any]]:
    if not isinstance(row, list):
        raise ValueError(f"Section {section_name!r}, row {test_name!r} must be an array")
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


def optional_string(data: dict[str, Any], key: str) -> str:
    value = data.get(key)
    if isinstance(value, str):
        return value
    return ""


def short_version(text: str) -> str:
    lines = text.strip().splitlines()
    return lines[0] if lines else ""


def format_runtime_version(name: str, text: str) -> str:
    if not text:
        # Missing runtime renders as "<Display> -" so the reader can see we
        # tried to detect it (vs. it being plain omitted).
        labels = {"lua": "Lua", "luajit": "LuaJIT", "luau": "Luau",
                  "mono": "Mono", "dotnet": ".NET", "quickjs": "QuickJS", "quirrel": "Quirrel"}
        return f"{labels.get(name, name)} -"
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
        # macOS qjs -h prints `QuickJS - Type "\h" for help` then `version <ver>`;
        # Windows qjs.exe (built from source) prints just the version as line 1.
        # Normalize both to `QuickJS <ver>`.
        marker = "version "
        if marker in line:
            return f"QuickJS {line.split(marker, 1)[1]}"
        if line.startswith("QuickJS"):
            return line
        return f"QuickJS {line}"
    if name == "quirrel":
        return f"Quirrel {line.split(' Copyright', 1)[0]}"
    return line


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
    profiles_dir = Path(args.profiles_dir).resolve()
    profiles = find_profiles(profiles_dir)
    snapshot = build_snapshot(profiles, readme_path)
    if args.stdout:
        print(snapshot)
        return 0
    update_readme(readme_path, snapshot)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
