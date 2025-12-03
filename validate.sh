#!/usr/bin/env bash
# Quick validation script to check if the setup is correct before running collectors

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "=========================================="
echo "Dynatrace OTEL Setup Validation"
echo "=========================================="
echo ""

# Check 1: Python version
echo "[1/6] Checking Python..."
if python3 --version >/dev/null 2>&1; then
  PYTHON_VERSION=$(python3 --version)
  echo "✓ $PYTHON_VERSION"
else
  echo "✗ Python 3 not found"
  exit 1
fi
echo ""

# Check 2: Virtual environment
echo "[2/6] Checking virtual environment..."
if [ -d ".venv" ] && [ -f ".venv/bin/python" ]; then
  echo "✓ Virtual environment exists at .venv/"
else
  echo "✗ Virtual environment not found. Running setup..."
  python3 -m venv .venv
  . .venv/bin/activate
  pip install -q -r requirements.txt
  echo "✓ Virtual environment created and dependencies installed"
fi
echo ""

# Check 3: Python dependencies
echo "[3/6] Checking Python dependencies..."
. .venv/bin/activate
MISSING_DEPS=0
for dep in flask prometheus_client psutil; do
  if python -c "import $dep" 2>/dev/null; then
    echo "✓ $dep installed"
  else
    echo "✗ $dep not installed"
    MISSING_DEPS=1
  fi
done
if [ $MISSING_DEPS -eq 1 ]; then
  echo "Installing missing dependencies..."
  pip install -q -r requirements.txt
fi
echo ""

# Check 4: Configuration files
echo "[4/6] Checking configuration files..."
for file in config.yaml dynatrace-collector-config.yaml app.py requirements.txt; do
  if [ -f "$file" ]; then
    echo "✓ $file exists"
  else
    echo "✗ $file missing"
    exit 1
  fi
done
echo ""

# Check 5: OTel Collector binary
echo "[5/6] Checking OpenTelemetry Collector binary..."
OTELCOL_BIN="${OTELCOL_BIN:-otelcol-contrib}"
if command -v "$OTELCOL_BIN" &>/dev/null; then
  OTELCOL_VERSION=$($OTELCOL_BIN version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' | head -1 || echo "unknown")
  echo "✓ $OTELCOL_BIN found (version: $OTELCOL_VERSION)"
else
  echo "✗ $OTELCOL_BIN not found in PATH"
  echo "  Download from: https://github.com/open-telemetry/opentelemetry-collector-releases/releases"
  echo "  Or set OTELCOL_BIN=/path/to/binary"
fi
echo ""

# Check 6: Dynatrace credentials
echo "[6/6] Checking Dynatrace credentials..."
if [ -z "${DYNATRACE_API_TOKEN:-}" ]; then
  echo "⚠ DYNATRACE_API_TOKEN not set"
  echo "  Set with: export DYNATRACE_API_TOKEN='dt0c01.DSCEQQIANNUYLJDHSGXBGG4D...'"
else
  echo "✓ DYNATRACE_API_TOKEN is set (${DYNATRACE_API_TOKEN:0:20}...)"
fi

if [ -z "${DYNATRACE_TENANT_URL:-}" ]; then
  echo "⚠ DYNATRACE_TENANT_URL not set"
  echo "  Set with: export DYNATRACE_TENANT_URL='https://wby64806.live.dynatrace.com'"
else
  echo "✓ DYNATRACE_TENANT_URL is set ($DYNATRACE_TENANT_URL)"
fi
echo ""

echo "=========================================="
echo "Validation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Set environment variables:"
echo "     export DYNATRACE_API_TOKEN='<your-api-token>'"
echo "     export DYNATRACE_TENANT_URL='https://<your-tenant>.live.dynatrace.com'"
echo ""
echo "  2. Run one of these:"
echo "     ./run-collector.sh          # Start OTel Collector Contrib"
echo "     ./run-dynatrace-collector.sh # Start Dynatrace OTel Collector"
echo "     ./start-both.sh              # Start both collectors"
echo ""
