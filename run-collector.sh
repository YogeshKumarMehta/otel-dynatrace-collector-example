#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# Create venv and install python deps
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
. .venv/bin/activate
pip install --upgrade pip >/dev/null 2>&1 || true
pip install -r requirements.txt >/dev/null 2>&1 || true

echo "Starting python metrics app..."
.venv/bin/python app.py &>/tmp/python-app.log &
APP_PID=$!

# Collector binary name (set OTELCOL_BIN env to override)
OTELCOL_BIN="${OTELCOL_BIN:-otelcol-contrib}"
if ! command -v "$OTELCOL_BIN" &>/dev/null; then
  echo "Error: $OTELCOL_BIN not found. Please download the OpenTelemetry Collector Contrib binary and put it in PATH or set OTELCOL_BIN to its path."
  echo "Example: curl -Lo /usr/local/bin/otelcol-contrib https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.141.0/otelcol-contrib_0.141.0_linux_amd64"
  echo "Python app logs: /tmp/python-app.log"
  exit 1
fi

: "${DYNATRACE_API_TOKEN:?Set DYNATRACE_API_TOKEN in your shell}"
: "${DYNATRACE_TENANT_URL:?Set DYNATRACE_TENANT_URL in your shell (https://<your-tenant>.live.dynatrace.com)}"

echo "Starting OpenTelemetry Collector (contrib) with config.yaml..."
exec "$OTELCOL_BIN" --config "$ROOT_DIR/config.yaml"

# when collector exits, the exec above terminates this script; background python app remains (you can kill it manually)
