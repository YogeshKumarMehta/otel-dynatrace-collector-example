# Dynatrace API Token Setup Guide

## Creating Your API Token

This guide walks you through creating a Dynatrace API token with the correct scopes for OpenTelemetry metrics ingestion.

## Step-by-Step Instructions

### 1. Log into Dynatrace SaaS

1. Go to: `https://<your-tenant>.live.dynatrace.com`
2. Log in with your credentials

### 2. Navigate to API Tokens

1. Click **Settings** (gear icon in top right)
2. Select **API tokens** from the left menu
3. Click **Create new token** button

### 3. Configure Your Token

**Token Name:** (Required)
```
otel-metrics-collector
```
(Or any descriptive name you prefer)

**Scopes:** (Check these boxes)

| Scope Name | Scope ID | Required | Purpose |
|-----------|----------|----------|---------|
| **Ingest metrics** | `metrics.ingest` | ✅ YES | Push Prometheus metrics via OTLP HTTP |
| **Ingest logs** | `logs.ingest` | ❌ NO | Only needed if sending OpenTelemetry logs |
| **Ingest OpenTelemetry traces** | `openTelemetryTrace.ingest` | ❌ NO | Only needed if sending distributed traces |

**Minimum Required (for this project):**
- ✅ `metrics.ingest` (essential - this is the only one you need!)

**Full Stack (if you want to add logs/traces later):**
- ✅ `metrics.ingest` (metrics)
- ✅ `logs.ingest` (logs)
- ✅ `openTelemetryTrace.ingest` (traces)

### 4. Create and Copy Token

1. Click **Create token** button
2. Your token appears in format: `dt0c01.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`
3. Click **Copy** to copy to clipboard
4. **⚠️ Important:** Save this token somewhere safe. You won't be able to view it again.

### 5. Store in Your Environment

#### Option A: Using `.env` file (Recommended)

```bash
# Copy the template
cp .env.example .env

# Edit with your token
vim .env
# or
nano .env
```

Add your actual values:
```bash
DYNATRACE_API_TOKEN="dt0c01.YOUR_COPIED_TOKEN_HERE"
DYNATRACE_TENANT_URL="https://your-tenant-id.live.dynatrace.com"
```

Then source it before running:
```bash
source .env
./run-collector.sh
```

#### Option B: Export as Environment Variable

```bash
export DYNATRACE_API_TOKEN="dt0c01.YOUR_COPIED_TOKEN_HERE"
export DYNATRACE_TENANT_URL="https://your-tenant-id.live.dynatrace.com"
./run-collector.sh
```

#### Option C: Permanent Shell Configuration

Add to your `~/.bashrc` or `~/.zshrc`:
```bash
export DYNATRACE_API_TOKEN="dt0c01.YOUR_COPIED_TOKEN_HERE"
export DYNATRACE_TENANT_URL="https://your-tenant-id.live.dynatrace.com"
```

Then reload:
```bash
source ~/.bashrc  # or ~/.zshrc
./run-collector.sh
```

## Finding Your Tenant ID

Your Dynatrace tenant ID is visible in your environment URL:

- **URL:** `https://abc12345.live.dynatrace.com`
- **Tenant ID:** `abc12345`
- **Full URL to use:** `https://abc12345.live.dynatrace.com`

**Important:** Use `.live` domain (not `.apps`)

## Verification

Test that your token works:

```bash
# Make a test request to Dynatrace API
curl -X POST \
  "https://<your-tenant>.live.dynatrace.com/api/v2/otlp/v1/metrics" \
  -H "Authorization: Api-Token $DYNATRACE_API_TOKEN" \
  -H "Content-Type: application/x-protobuf" \
  --data "test"
```

If you get a `400` or `401` error:
- ✅ `400 Bad Request` = Token is valid but data format is wrong (normal for test)
- ❌ `401 Unauthorized` = Token is invalid or wrong scope
- ❌ `404 Not Found` = Tenant URL is incorrect (check `.live` vs `.apps`)

## Troubleshooting

### "Invalid API token"
- Token was not copied correctly
- Token format must start with `dt0c01.`
- Check for extra spaces or characters

### "API token does not have the required scope"
- Missing `metrics.ingest` scope
- Create a new token with correct scopes

### "Cannot connect to Dynatrace"
- Check tenant URL (use `.live`, not `.apps`)
- Verify internet connectivity
- Check firewall/proxy settings

### "401 Unauthorized" during metrics push
- Token expired (tokens may have expiration dates)
- Wrong API token
- Insufficient permissions

## Security Best Practices

1. **Never commit tokens to Git**
   - Use `.env` (which is in `.gitignore`)
   - Use environment variables
   - Use `.env.example` as template only

2. **Rotate tokens regularly**
   - Generate new tokens periodically
   - Delete old tokens in Dynatrace

3. **Limit token scope**
   - Only enable required scopes
   - Don't enable unnecessary permissions

4. **Store safely**
   - Don't share tokens in messages/emails
   - Don't hardcode in scripts
   - Use environment variables or `.env` files

## Token Scope Details

### `metrics.ingest` (✅ REQUIRED FOR THIS PROJECT)
- **API:** Metrics API v2
- **Permission:** POST ingest data points
- **Purpose:** Allows pushing metrics via OpenTelemetry OTLP HTTP endpoint
- **Usage:** You NEED this to send Prometheus metrics to Dynatrace

### `logs.ingest` (○ OPTIONAL - Not used in this project)
- **API:** Log Monitoring API v2
- **Permission:** POST ingest logs
- **Purpose:** Allows pushing logs via OpenTelemetry
- **Usage:** Only if you want to ingest logs from your app (we're not doing this)

### `openTelemetryTrace.ingest` (○ OPTIONAL - Not used in this project)
- **API:** OpenTelemetry Trace API
- **Permission:** Ingest traces
- **Purpose:** Allows pushing distributed traces via OpenTelemetry
- **Usage:** Only if you want to ingest traces (we're not doing this)

## Next Steps

Once your token is created and configured:

1. Start the collector:
   ```bash
   source .env
   ./run-collector.sh
   ```

2. Verify metrics in Dynatrace:
   - Go to: **Metrics** → **Metrics Browser**
   - Search: `system_cpu_usage_percent`
   - You should see your metrics flowing in

3. Check collector health:
   ```bash
   curl http://localhost:8888/metrics | grep "otelcol_exporter"
   ```

## References

- [Dynatrace API Tokens Documentation](https://docs.dynatrace.com/docs/shortlink/api-authentication)
- [OTLP Ingest API](https://docs.dynatrace.com/docs/shortlink/metrics-api-v2)
- [OpenTelemetry Integration](https://docs.dynatrace.com/docs/extend-dynatrace/opentelemetry/)

---

**You're all set!** Your API token is ready to use with this OpenTelemetry Collector setup. 🎉
