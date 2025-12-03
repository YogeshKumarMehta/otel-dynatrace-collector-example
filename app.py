from flask import Flask, Response
from prometheus_client import Gauge, generate_latest, CollectorRegistry
import os
import random
import time
from threading import Thread
import psutil

app = Flask(__name__)
registry = CollectorRegistry()

# Simple gauge metric for testing
g = Gauge("simple_dummy_metric", "Simple dummy metric for Dynatrace testing", registry=registry)

cpu_gauge = Gauge(
    "system_cpu_usage_percent",
    "System CPU usage percentage (0-100)",
    ["host", "env"],
    registry=registry
)
cpu_free_gauge = Gauge(
    "system_cpu_free_percent",
    "System CPU free percentage (0-100)",
    ["host", "env"],
    registry=registry
)
memory_used_gauge = Gauge(
    "system_memory_used_bytes",
    "System memory used in bytes",
    ["host", "env"],
    registry=registry
)
process_memory_rss_gauge = Gauge(
    "process_memory_rss_bytes",
    "Resident Set Size (RSS) memory used by this Python process in bytes",
    ["host", "env"],
    registry=registry,
)
disk_free_gauge = Gauge(
    "system_disk_free_bytes",
    "System disk free space in bytes (root)",
    ["host", "env"],
    registry=registry,
)
load_avg_gauge = Gauge(
    "system_load_avg_1min",
    "System load average (1 min)",
    ["host", "env"],
    registry=registry,
)

def update_metrics():
    while True:
        base = float(os.environ.get("METRIC_VALUE", random.uniform(10, 100)))
        g.set(base + random.uniform(-3, 3))
        # Update psutil metrics
        try:
            # Custom label values
            host = os.environ.get("HOSTNAME", os.uname().nodename)
            env = os.environ.get("ENV", "dev")

            # system-wide CPU percent (non-blocking with interval=None)
            cpu_percent = psutil.cpu_percent(interval=None)
            cpu_gauge.labels(host=host, env=env).set(cpu_percent)
            cpu_free_gauge.labels(host=host, env=env).set(100.0 - cpu_percent)

            # process RSS memory in bytes
            process = psutil.Process(os.getpid())
            proc_mem = process.memory_info().rss
            process_memory_rss_gauge.labels(host=host, env=env).set(proc_mem)

            # memory used (bytes)
            mem = psutil.virtual_memory()
            memory_used_gauge.labels(host=host, env=env).set(mem.used)

            # disk free space (root)
            disk = psutil.disk_usage("/")
            disk_free_gauge.labels(host=host, env=env).set(disk.free)

            # system load average (1 min)
            load_avg = os.getloadavg()[0] if hasattr(os, "getloadavg") else 0.0
            load_avg_gauge.labels(host=host, env=env).set(load_avg)
        except Exception as e:
            # Do not fail the application if psutil metrics can't be collected
            print(f"Error collecting metrics: {e}")
        time.sleep(2)


@app.route("/metrics")
def metrics():
    return Response(generate_latest(registry), mimetype="text/plain; version=0.0.4; charset=utf-8")


@app.route("/")
def index():
    return "Dynatrace test app - /metrics"


if __name__ == "__main__":
    Thread(target=update_metrics, daemon=True).start()
    # Use 0.0.0.0 so the Collector running on the same WSL host can reach it
    app.run(host="0.0.0.0", port=8000)
