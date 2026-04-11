#!/usr/bin/env python3
"""Host-side wrapper for the runtime HH helper that lives in .openshell/."""

from __future__ import annotations

import os
import sys
from pathlib import Path


def main() -> int:
    script_path = Path(__file__).resolve().parents[1] / ".openshell" / "bin" / "openclaw-hh-vacancies"
    if not script_path.exists():
        print(f"Runtime helper not found: {script_path}", file=sys.stderr)
        return 1

    os.execv(sys.executable, [sys.executable, str(script_path), *sys.argv[1:]])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
