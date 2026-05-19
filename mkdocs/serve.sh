#!/usr/bin/env bash
# Local docs preview with live-reload.
#
#   ./serve.sh          # serve at http://127.0.0.1:8001 with auto-reload
#   ./serve.sh build    # one-shot static build into ./site
#
# Uses python3 -m mkdocs so it works whether or not `mkdocs` is on PATH.
# Port 8001 avoids clashing with VidaiMock's default 8100 and other local apps.
set -euo pipefail
cd "$(dirname "$0")"

if ! python3 -c "import mkdocs" 2>/dev/null; then
  echo "mkdocs not found. Install with:  python3 -m pip install -r requirements.txt"
  exit 1
fi

case "${1:-serve}" in
  build)
    python3 -m mkdocs build --strict
    echo "Built to ./site"
    ;;
  serve|*)
    python3 -m mkdocs serve --dev-addr 127.0.0.1:8001
    ;;
esac
