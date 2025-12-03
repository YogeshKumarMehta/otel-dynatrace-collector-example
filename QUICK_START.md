# Quick Start Guide

## 1️⃣ Get Your Dynatrace Access Token

See **[API_TOKEN_SETUP.md](./API_TOKEN_SETUP.md)** for detailed step-by-step instructions.

**Quick recap:**
```bash
export DYNATRACE_API_TOKEN="<your-access-token>"
export DYNATRACE_TENANT_URL="https://<your-tenant>.live.dynatrace.com"
```

## 2️⃣ Start the Collector

```bash
./run-collector.sh
```

This will:
1. Create Python virtual environment (if needed)
2. Start Python Flask app (port 8000)
3. Start OTel Collector (port 8888)

## 3️⃣ Verify Everything is Running

In another terminal:

```bash
# Check Python app is exposing metrics
curl http://localhost:8000/metrics | grep system_cpu_usage_percent

# Check collector is working
curl http://localhost:8888/metrics | grep "otelcol_exporter_sent"
```

## 4️⃣ View Metrics in Dynatrace

1. Go to: `https://<your-tenant>.live.dynatrace.com`
2. Navigate to: **Metrics** → **Metrics Browser**
3. Search for: `system_cpu_usage_percent`

## 🛑 Stop Everything

```bash
pkill -f "otelcol-contrib"
pkill -f "python app.py"
```

---

## � Ports

- `8000` - Python app metrics endpoint
- `8888` - OTel Collector internal metrics

---

## ❓ Common Issues

| Problem | Solution |
|---------|----------|
| Port already in use | `pkill -f otelcol-contrib && sleep 2 && ./run-collector.sh` |
| Metrics not in Dynatrace | Check token & tenant URL (see API_TOKEN_SETUP.md) |
| "otelcol-contrib: command not found" | Install binary (see README.md) |
| No metrics showing | Run `curl http://localhost:8000/metrics` to verify app is working |

---

## 📊 Available Metrics

All metrics have labels: `host` and `env`

- `system_cpu_usage_percent` - CPU usage (0-100%)
- `system_cpu_free_percent` - CPU free (0-100%)
- `system_memory_used_bytes` - Memory used (bytes)
- `system_disk_free_bytes` - Disk free (bytes)
- `system_load_avg_1min` - Load average (1 min)
- `process_memory_rss_bytes` - Python process memory (bytes)
- `simple_dummy_metric` - Test metric (0-100)

---

## 🔍 Pre-Flight Checks

To validate your setup before running:

```bash
./validate.sh
```

This checks:
- ✅ Python 3 installed
- ✅ Virtual environment configured
- ✅ Python dependencies available
- ✅ Configuration files present
- ✅ otelcol-contrib binary accessible
- ✅ Dynatrace credentials set

---

## 📚 For More Details

- **Access Token Creation**: See [API_TOKEN_SETUP.md](./API_TOKEN_SETUP.md)
- **Full Documentation**: See [README.md](./README.md)
- **Architecture & Troubleshooting**: See [README.md](./README.md)

---

**That's it!** You're pushing Prometheus metrics to Dynatrace via OpenTelemetry. 🎉

### Prerequisites

- **otelcol-contrib** binary in PATH
- **Python 3.8+**
- **Linux/WSL environment**

### Installing otelcol-contrib

```bash
# Download latest version
curl -Lo /usr/local/bin/otelcol-contrib \
  https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.141.0/otelcol-contrib_0.141.0_linux_amd64

chmod +x /usr/local/bin/otelcol-contrib
otelcol-contrib version
```

**For ARM64:** Use `linux_arm64` instead of `linux_amd64` in the URL.

### Custom Metrics

Edit `app.py` to add your own metrics:

```python
from prometheus_client import Gauge
my_custom_metric = Gauge('my_metric', 'My custom metric')
# Then use it in update_metrics()
```

### Persistent Credentials

Create `~/.dynatrace-env`:

```bash
export DYNATRACE_API_TOKEN="<your-api-token>"
export DYNATRACE_TENANT_URL="https://<your-tenant>.live.dynatrace.com"
```

Then before running:
```bash
source ~/.dynatrace-env
./run-collector.sh
```

---

**Need more help?** See [README.md](./README.md) for complete documentation.
