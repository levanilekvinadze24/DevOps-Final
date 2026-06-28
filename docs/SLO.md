# Service Level Objectives — Observability Lab

## Availability SLO

| Metric | Target | Measurement Window | Alert |
|--------|--------|--------------------|-------|
| HTTP success rate (2xx/3xx) | **99%** | 5-minute rolling | `SLOAvailabilityBreach` |

**PromQL (success ratio):**

```promql
sum(rate(app_requests_total{status=~"2..|3.."}[5m]))
/
sum(rate(app_requests_total[5m]))
```

## Error Budget

With a 99% availability target over 30 days:

- **Allowed downtime:** ~7.2 hours/month
- **Error budget burn alert:** `HighErrorRateWarning` fires when >10 errors occur in 5 minutes

## Latency (informational)

Request duration is logged in structured JSON (`duration_ms` field). Query in Loki:

```logql
{container="observability-lab-app"} | json | duration_ms > 500
```

## Incident severity mapping

| Severity | Condition | Response time |
|----------|-----------|---------------|
| P1 Critical | `ApplicationDown`, `HighApplicationErrorRate` | Immediate |
| P2 Warning | `SLOAvailabilityBreach`, `HighErrorRateWarning` | Within 30 minutes |
