#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/Scripts/build.sh"
open "$ROOT/.build/KeyboardCleaner.app"
