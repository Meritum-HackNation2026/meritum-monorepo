#!/usr/bin/env python3
"""Rows for the README cost table, from CheckRecords exported as JSON lines.

Run by hand after a check run on real providers, never in CI (ADR-18, ADR-28).
Standard library only, so it runs without the worker's environment:

    python scripts/measure_costs.py records.jsonl

Each line is one ``CheckRecord`` (meritum-core). The cost of every ``models`` entry is
grouped by ``provider/model``; the worker writes web search as its own entry
(meritum-worker#26), so the search cost shows up as one more group. Gates that do not
write a ``models`` entry are not counted and the output says so.

Features:
    US-OBS-02, US-WDR-03, F-20, ADR-18
"""

import argparse
import json
from collections import defaultdict
from datetime import UTC, datetime
from pathlib import Path

PER_CHECKS = 1000


def summarize(lines: list[str]) -> dict:
    """Cost of 1,000 checks per provider/model and per channel, and cache hits."""
    records = [json.loads(line) for line in lines if line.strip()]
    count = len(records)
    by_model: dict[str, float] = defaultdict(float)
    by_channel: dict[str, list[float]] = defaultdict(list)
    for record in records:
        total = 0.0
        for usage in record.get("models", []):
            cost = float(usage.get("cost_usd", 0.0))
            by_model[f"{usage['provider']}/{usage['model']}"] += cost
            total += cost
        by_channel[record["channel"]].append(total)
    hits = sum(bool(r.get("cache_hit")) for r in records)
    scale = PER_CHECKS / count if count else 0.0
    return {
        "checks": count,
        "usd_per_1000_checks": sum(by_model.values()) * scale,
        "by_model": {k: v * scale for k, v in sorted(by_model.items())},
        "by_channel": {
            k: {"checks": len(v), "usd_per_1000_checks": sum(v) / len(v) * PER_CHECKS}
            for k, v in sorted(by_channel.items())
        },
        "cache_hit_ratio": hits / count if count else 0.0,
    }


def markdown(summary: dict, measured_on: str) -> str:
    """README rows with the measurement date."""
    parts = ", ".join(f"{k}: {v:.4f} USD" for k, v in summary["by_model"].items())
    channels = ", ".join(
        f"{k}: {v['usd_per_1000_checks']:.4f} USD ({v['checks']} sprawdzeń)"
        for k, v in summary["by_channel"].items()
    )
    note = "bramki bez wpisu w `models` nie są wliczone"
    return "\n".join(
        [
            f"| Koszt 1 000 zapytań | {summary['usd_per_1000_checks']:.4f} USD "
            f"({summary['checks']} sprawdzeń, {measured_on}); {parts}; {note} |",
            f"| Koszt 1 000 zapytań wg kanału | {channels} |",
            f"| Odsetek trafień w pamięci wyników | {summary['cache_hit_ratio']:.1%} "
            f"({measured_on}) |",
        ]
    )


def main() -> None:
    """Print the JSON summary and the README rows."""
    parser = argparse.ArgumentParser(prog="measure_costs")
    parser.add_argument("records", type=Path, help="CheckRecords, one JSON per line")
    parser.add_argument("--date", default=datetime.now(UTC).date().isoformat())
    args = parser.parse_args()
    summary = summarize(args.records.read_text(encoding="utf-8").splitlines())
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    print()
    print(markdown(summary, args.date))


if __name__ == "__main__":
    main()
