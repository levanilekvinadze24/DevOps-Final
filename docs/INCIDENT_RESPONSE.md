# Incident Response Runbook

## Overview

This runbook describes how to detect, triage, and recover from incidents in the DevOps Observability Lab stack.

## Detection channels

1. **Prometheus alerts** — http://localhost:9090/alerts
2. **Grafana unified alerting** — http://localhost:3000/alerting/list
3. **Alertmanager** — http://localhost:9093
4. **Health monitor script** — `scripts/health-monitor.sh` or `scripts/health-monitor.ps1`

## Severity levels

| Level | Alerts | Action |
|-------|--------|--------|
| P1 Critical | `ApplicationDown`, `HighApplicationErrorRate` | Immediate investigation |
| P2 Warning | `SLOAvailabilityBreach`, `HighErrorRateWarning` | Monitor and investigate within 30 min |

## Response procedure

### 1. Acknowledge

- Confirm the alert in Grafana or Alertmanager
- Note the alert name, time, and affected service

### 2. Triage

```bash
# Check container status
docker compose ps

# Application logs
docker compose logs app --tail=100

# Query error logs in Grafana Explore (Loki)
# {container="observability-lab-app"} | json | level="ERROR"
```

### 3. Mitigate

**Application unhealthy:**

```bash
docker compose restart app
./scripts/validate-environment.sh
```

**Failed deployment:**

```bash
./scripts/rollback.sh        # Linux/macOS
.\scripts\rollback.ps1       # Windows
```

**Full stack recovery:**

```bash
docker compose down
./scripts/setup.sh           # Linux/macOS
.\scripts\setup.ps1          # Windows
```

### 4. Verify recovery

```bash
./scripts/validate-environment.sh
curl http://localhost:5000/health
curl http://localhost:5000/ready
```

Check Prometheus targets are `UP` at http://localhost:9090/targets.

### 5. Post-incident

- Document root cause and timeline
- Review whether alert thresholds need tuning
- Update runbook if a new failure mode was discovered

## Simulating incidents (lab only)

```bash
# Trigger critical error-rate alert
./scripts/trigger-alert.sh

# Generate normal traffic for dashboards
./scripts/generate-traffic.ps1   # Windows
```

## Escalation

For this lab environment, all alerts route to Alertmanager receivers (`critical-receiver`, `warning-receiver`). In production, configure webhook/email/Slack receivers in `alertmanager/alertmanager.yml`.
