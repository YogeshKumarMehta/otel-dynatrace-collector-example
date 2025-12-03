# Quick Start Guide

## 1️⃣ Set Environment Variables

```bash
export DYNATRACE_API_TOKEN="<your-api-token>"
export DYNATRACE_TENANT_URL="https://<your-tenant>.live.dynatrace.com"
```

**Where to get these:**
- **API Token**: See "Creating a Dynatrace API Token" section below
- **Tenant URL**: Your Dynatrace environment URL (e.g., `https://xyz123.live.dynatrace.com`)

### Creating a Dynatrace API Token

1. Log into your **Dynatrace SaaS** account
2. Navigate to: **Settings** → **API tokens**
3. Click **Create new token**
4. Enter a token name (e.g., `otel-metrics-collector`)
5. **Enable this required scope:**
   - ✅ **Ingest metrics** (`metrics.ingest`) - For OpenTelemetry metrics ← THIS IS REQUIRED
6. **Optional scopes** (only if you want logs/traces):
   - ○ **Ingest logs** (`logs.ingest`) - Optional, only if sending logs
   - ○ **Ingest OpenTelemetry traces** (`openTelemetryTrace.ingest`) - Optional, only if sending traces
7. Click **Create token**
8. Copy the token (format: `dt0c01.XXXXXXX...`)
9. Paste into your `.env` file or export as environment variable

**Minimum required scope:** `metrics.ingest` (that's it for this project!)

## 2️⃣ Start the Collector

```bash
cd otel-dynatrace-collector
./run-collector.sh
```

## 3️⃣ Verify Everything is Running

```bash
# Check Python app metrics
curl http://localhost:8000/metrics | grep system_

# Check collector internal metrics
curl http://localhost:8888/metrics | head -10
```

## 4️⃣ View Metrics in Dynatrace

1. Go to: https://<your-tenant>.live.dynatrace.com
2. Navigate to: **Metrics** → **Metrics Browser**
3. Search for: `system_cpu_usage_percent`

## 🛑 Stop Everything

```bash
pkill -f "otelcol-contrib"
pkill -f "python app.py"
```

## 📊 Expected Output

### Python App Metrics (localhost:8000/metrics)
```
# HELP system_cpu_usage_percent System CPU usage percentage (0-100)
# TYPE system_cpu_usage_percent gauge
system_cpu_usage_percent{env="dev",host="<your-hostname>"} 2.5

# HELP system_memory_used_bytes System memory used in bytes
# TYPE system_memory_used_bytes gauge
system_memory_used_bytes{env="dev",host="<your-hostname>"} 4.93e+09
```

### Collector Metrics (localhost:8888/metrics)
```
otelcol_exporter_queue_size{exporter="otlphttp",...} 0
otelcol_receiver_accepted_metric_points{receiver="prometheus",...} 7
```

## ⚙️ What Happens

1. **Python app** (port 8000) - Exposes 7 Prometheus metrics every 2 seconds
2. **OTel Collector** - Scrapes metrics, batches them, exports via OTLP HTTP
3. **Dynatrace** - Receives metrics at `/api/v2/otlp` endpoint
4. **Metrics Browser** - Metrics appear with labels and are queryable

## 🔗 Ports

- `8000` - Python app metrics endpoint
- `8888` - OTel Collector internal metrics (Prometheus format)

## ❓ Common Issues

| Problem | Solution |
|---------|----------|
| Port already in use | `pkill -f otelcol-contrib && sleep 2 && ./run-collector.sh` |
| Metrics not in Dynatrace | Verify API token and tenant URL are correct |
| "Command not found: otelcol-contrib" | Install from [OpenTelemetry releases](https://github.com/open-telemetry/opentelemetry-collector-releases) |
| No metrics in Prometheus format | Check `curl http://localhost:8000/metrics` |

---

**That's it!** You're now pushing Prometheus metrics to Dynatrace via OpenTelemetry. 🎉

## ⚡ Quick Start

### Prerequisites

You need:
- **otelcol-contrib** binary in your PATH
- **Dynatrace credentials** (API token + tenant URL)
- **Linux/WSL environment** with Python 3.8+

#### Installing otelcol-contrib

If you don't have the binary, download and install it:

```bash
# Download latest version
curl -Lo /usr/local/bin/otelcol-contrib \
  https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.141.0/otelcol-contrib_0.141.0_linux_amd64

# Make it executable
chmod +x /usr/local/bin/otelcol-contrib

# Verify installation
otelcol-contrib version
```

**For different architectures:**
- **ARM64**: Replace `linux_amd64` with `linux_arm64`
- **Check releases**: https://github.com/open-telemetry/opentelemetry-collector-releases/releases

### Run It Now (3 commands)

```bash
# 1. Navigate to project
cd otel-dynatrace-collector

# 2. Export your Dynatrace credentials
export DYNATRACE_API_TOKEN="<your-api-token>"
export DYNATRACE_TENANT_URL="https://<your-tenant>.live.dynatrace.com"

# 3. Start the collector!
./run-collector.sh
```

That's it! In another terminal, verify:

```bash
curl http://localhost:8000/metrics | grep system_cpu_usage_percent
```

You should see metrics like:
```prometheus
system_cpu_usage_percent{env="dev",host="Yogesh-LAPTOP"} 2.9
```

---

## 🔧 Complete Setup

### Step 1: Validate Environment

```bash
cd otel-dynatrace-collector
./validate.sh
```

**Expected output:**
```
✓ Python 3.13.2
✓ Virtual environment exists at .venv/
✓ flask installed
✓ prometheus_client installed
✓ psutil installed
✓ config.yaml exists
✓ dynatrace-collector-config.yaml exists
✓ app.py exists
✓ requirements.txt exists
✓ otelcol-contrib found
```

### Step 2: Set Dynatrace Credentials

```bash
# Get your token from Dynatrace console: Settings → API tokens
export DYNATRACE_API_TOKEN="<your-api-token>"

# Your tenant URL
export DYNATRACE_TENANT_URL="https://<your-tenant>.live.dynatrace.com"
```

**Example:**
```bash
export DYNATRACE_API_TOKEN="dt0c01.ABC123DEF456..."
export DYNATRACE_TENANT_URL="https://abc12345.live.dynatrace.com"
```

### Step 3: Choose Your Deployment

**Option A: OTel Collector Only** (Recommended for first-time setup)
```bash
./run-collector.sh
```

**Option B: Dynatrace OTel Collector Only** (requires otelcol-dynatrace binary)
```bash
./run-dynatrace-collector.sh
```

**Option C: Both Collectors** (for testing/comparison)
```bash
./start-both.sh
```

### Step 4: Verify Metrics

Open another terminal and run:

```bash
# Check Python app is exposing metrics
curl http://localhost:8000/metrics | head -20

# If using OTel Collector, check Prometheus exporter
curl http://localhost:8888/metrics | grep "scrape" | head -10

# If using Dynatrace Collector, check its Prometheus exporter
curl http://localhost:8889/metrics | grep "scrape" | head -10
```

### Step 5: View in Dynatrace Console

1. Log in to: https://<your-tenant>.live.dynatrace.com
2. Go to: **Metrics** → **Metrics Browser**
3. Search for: `system_cpu_usage_percent`
4. You should see metrics with your custom labels (host, env)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Python Flask Metrics App (localhost:8000)                   │
│ ✓ 7 Prometheus metrics (CPU, memory, disk, load)           │
│ ✓ Custom labels: host, env                                 │
│ ✓ Updates every 2 seconds                                  │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP GET /metrics (5s scrape)
                       │
       ┌───────────────┴────────────────┐
       │                                │
       ▼                                ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│ OTel Collector Contrib   │  │ Dynatrace OTel Collector │
│ (config.yaml)            │  │ (dynatrace-...yaml)      │
│ Receiver: Prometheus     │  │ Receiver: Prometheus     │
│ Exporter: OTLP HTTP      │  │ Exporter: Dynatrace/OTLP │
│ Port 8888                │  │ Port 8889                │
└───────────┬──────────────┘  └────────────┬─────────────┘
            │ OTLP HTTP Export             │ Native/OTLP Export
            └───────────────┬──────────────┘
                            │
                            ▼
                  ┌──────────────────────┐
                  │ Dynatrace SaaS Tenant│
                  │ /api/v2/otlp         │
                  │ Metrics Browser      │
                  └──────────────────────┘
```

---

## 📁 File Reference

### **app.py** (3.2 KB)
Python Flask application exposing Prometheus metrics.

**Metrics (7 total):**
- `simple_dummy_metric` — Test metric (random 0-100)
- `system_cpu_usage_percent` — CPU usage %
- `system_cpu_free_percent` — CPU free %
- `system_memory_used_bytes` — Memory (bytes)
- `process_memory_rss_bytes` — Process memory (bytes)
- `system_disk_free_bytes` — Disk free (bytes)
- `system_load_avg_1min` — Load average

**Key features:**
- Background thread updates metrics every 2 seconds
- Custom labels: `host=Yogesh-LAPTOP`, `env=dev`
- Error handling for psutil failures
- Exposed on `http://localhost:8000/metrics`

---

### **config.yaml** (0.9 KB)
OpenTelemetry Collector configuration (OTLP HTTP export).

**Pipeline:**
```
Prometheus Receiver (localhost:8000/metrics, 5s scrape)
    ↓ (batch processor)
    ├→ OTLP HTTP Exporter (Dynatrace OTLP endpoint)
    ├→ Debug Exporter (stdout logging)
    └→ Prometheus Exporter (0.0.0.0:8888)
```

**Endpoint**: `https://<your-tenant>.live.dynatrace.com/api/v2/otlp` (configured via env var)

---

### **dynatrace-collector-config.yaml** (1.7 KB)
Dynatrace OTel Collector configuration (native exporter + fallback).

**Pipeline:**
```
Prometheus Receiver (localhost:8000/metrics, 5s scrape)
    ↓ (batch processor)
    ├→ Dynatrace Exporter (native)
    ├→ OTLP HTTP Exporter (fallback)
    └→ Prometheus Exporter (0.0.0.0:8889)
```

**Uses environment variables:**
- `${DYNATRACE_TENANT_URL}` — Your tenant URL
- `${DYNATRACE_API_TOKEN}` — Your API token

---

### **run-collector.sh** (1.4 KB) - Executable ✓
Start script for OTel Collector Contrib.

**What it does:**
1. Creates `.venv/` if not exists
2. Installs Python dependencies
3. Starts Python app (`app.py`)
4. Starts `otelcol-contrib` with `config.yaml`

**Usage:**
```bash
./run-collector.sh
```

---

### **run-dynatrace-collector.sh** (1.5 KB) - Executable ✓
Start script for Dynatrace OTel Collector.

**What it does:**
1. Checks if Python app is already running
2. Creates `.venv/` and installs deps if needed
3. Starts Python app (if not running)
4. Starts `otelcol-dynatrace` with `dynatrace-collector-config.yaml`

**Usage:**
```bash
./run-dynatrace-collector.sh
```

---

### **start-both.sh** (3.5 KB) - Executable ✓
Launcher to run both collectors simultaneously.

**What it does:**
1. Validates environment variables
2. Starts OTel Collector Contrib (port 8888)
3. Starts Dynatrace Collector (port 8889)
4. Displays status and logging information
5. Provides verification commands

**Usage:**
```bash
export DYNATRACE_API_TOKEN="..."
export DYNATRACE_TENANT_URL="..."
./start-both.sh
```

**Output:**
```
==========================================
Starting dual-collector setup
==========================================

Metrics app will run on:   http://localhost:8000/metrics
OTel Collector (OTLP):     http://localhost:8888/metrics
Dynatrace Collector:       http://localhost:8889/metrics

✓ OTel Collector started (PID: XXXXX)
✓ Dynatrace Collector started (PID: XXXXX)

Both collectors are running!
```

---

### **validate.sh** (2.0 KB) - Executable ✓
Pre-flight validation script.

**Checks:**
1. Python 3 availability
2. Virtual environment setup
3. Python dependencies (flask, prometheus_client, psutil)
4. Configuration files present
5. OTel Collector binary in PATH
6. Dynatrace credentials set

**Usage:**
```bash
./validate.sh
```

---

### **requirements.txt**
Python dependencies:
- **flask** (2.3.x) — Web framework
- **prometheus_client** (0.23.x) — Prometheus metrics
- **psutil** (5.9.x) — System metrics collection

---

### **README.md** (6.4 KB)
Complete documentation with troubleshooting.

### **SETUP_COMPLETE.md**
Quick reference guide and status summary.

---

## 📊 Metrics Available

All exposed on **http://localhost:8000/metrics**

| Metric | Type | Unit | Labels | Description |
|--------|------|------|--------|-------------|
| `simple_dummy_metric` | Gauge | — | — | Test metric (random 0-100) |
| `system_cpu_usage_percent` | Gauge | % | host, env | CPU utilization (0-100) |
| `system_cpu_free_percent` | Gauge | % | host, env | CPU free (0-100) |
| `system_memory_used_bytes` | Gauge | bytes | host, env | Memory used |
| `process_memory_rss_bytes` | Gauge | bytes | host, env | Python process RSS |
| `system_disk_free_bytes` | Gauge | bytes | host, env | Disk space free |
| `system_load_avg_1min` | Gauge | — | host, env | Load avg (1 min) |

**Example output:**
```prometheus
# HELP system_cpu_usage_percent System CPU usage percentage (0-100)
# TYPE system_cpu_usage_percent gauge
system_cpu_usage_percent{env="dev",host="<your-hostname>"} 2.9

# HELP system_memory_used_bytes System memory used in bytes
# TYPE system_memory_used_bytes gauge
system_memory_used_bytes{env="dev",host="<your-hostname>"} 4.957790208e+09
```

---

## 🔍 Verification Checklist

- [ ] `./validate.sh` shows all checks passing
- [ ] `curl http://localhost:8000/metrics` returns metrics
- [ ] OTel Collector Prometheus exporter responds: `curl http://localhost:8888/metrics`
- [ ] Metrics appear in Dynatrace console with correct labels
- [ ] No errors in `/tmp/collector.log` and `/tmp/python-app.log`

---

## ⚠️ Troubleshooting

### **"otelcol-contrib: command not found"**
```bash
# Download the binary
curl -Lo /usr/local/bin/otelcol-contrib \
  https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.141.0/otelcol-contrib_0.141.0_linux_amd64

chmod +x /usr/local/bin/otelcol-contrib

# Verify
otelcol-contrib version
```

---

### **"DYNATRACE_API_TOKEN not set"**
```bash
# Set credentials before running scripts
export DYNATRACE_API_TOKEN="<your-api-token>"
export DYNATRACE_TENANT_URL="https://<your-tenant>.live.dynatrace.com"
```

---

### **"Failed to connect to localhost:8000"**
Python app isn't running. Check logs:
```bash
tail -f /tmp/python-app.log
```

If `.venv` doesn't exist:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

---

### **"Metrics not appearing in Dynatrace"**
Check collector logs:
```bash
# OTel Collector
tail -f /tmp/collector.log | grep -i "error\|export\|otlp"

# Dynatrace Collector
tail -f /tmp/dynatrace-collector.log | grep -i "error"
```

Common issues:
- API token expired or invalid
- Tenant URL incorrect (should be `.live`, not `.apps`)
- Network connectivity to Dynatrace endpoint
- Wrong endpoint path (should be `/api/v2/otlp`)

---

### **"Port 8000/8888/8889 already in use"**
Kill existing processes:
```bash
pkill -f "python app.py"
pkill -f "otelcol"
```

Or use different ports (edit config.yaml):
```yaml
prometheus:
  config:
    scrape_configs:
      - targets: ["localhost:9000"]  # Change from 8000
```

---

## 🚀 Advanced Usage

### Using Custom Metrics

Edit `app.py` to add your own metrics:

```python
from prometheus_client import Gauge

# Add at top of file
my_custom_metric = Gauge('my_metric', 'My custom metric', ['label1', 'label2'])

# In update_metrics() function:
my_custom_metric.labels(label1='value1', label2='value2').set(42)
```

---

### Switching Export Modes

**OTLP HTTP (default):**
```bash
./run-collector.sh  # Uses config.yaml
```

**Dynatrace Native Exporter:**
```bash
./run-dynatrace-collector.sh  # Uses dynatrace-collector-config.yaml
```

**Both Simultaneously:**
```bash
./start-both.sh  # Runs both with port isolation
```

---

### Monitoring the Collectors

View internal metrics:

```bash
# OTel Collector internals (Prometheus format)
curl http://localhost:8888/metrics | grep "otelcol" | head -10

# Dynatrace Collector internals
curl http://localhost:8889/metrics | grep "otelcol" | head -10
```

---

### Persistent Credentials

To avoid exporting credentials each time, create `~/.dynatrace-env`:

```bash
#!/bin/bash
export DYNATRACE_API_TOKEN="<your-api-token>"
export DYNATRACE_TENANT_URL="https://<your-tenant>.live.dynatrace.com"
```

Then before running:
```bash
source ~/.dynatrace-env
./run-collector.sh
```

---

## 📚 Additional Resources

- **OpenTelemetry Docs**: https://opentelemetry.io/docs/
- **Dynatrace OTLP Integration**: https://docs.dynatrace.com/docs/extend-dynatrace/opentelemetry/
- **Prometheus Metrics Format**: https://prometheus.io/docs/concepts/data_model/
- **OTel Collector Releases**: https://github.com/open-telemetry/opentelemetry-collector-releases/releases

---

## ✅ Summary

**You have everything ready to start sending metrics to Dynatrace!**

1. Run: `./validate.sh` to confirm setup
2. Export Dynatrace credentials
3. Start with: `./run-collector.sh`
4. Verify metrics at: `http://localhost:8000/metrics`
5. Check Dynatrace console: https://<your-tenant>.live.dynatrace.com

**Questions?** Check `README.md` for detailed documentation or `SETUP_COMPLETE.md` for quick reference.

**Happy monitoring!** 🎉
