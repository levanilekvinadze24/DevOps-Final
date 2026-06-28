import json
import logging
import os
import random
import sys
import time
from datetime import datetime, timezone

from flask import Flask, jsonify, request
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

REQUEST_COUNTER = Counter(
    "app_requests_total",
    "Total number of HTTP requests",
    ["method", "endpoint", "status"],
)
ERROR_COUNTER = Counter(
    "app_errors_total",
    "Total number of application errors",
    ["error_type"],
)


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
            "service": "observability-lab-app",
        }
        if hasattr(record, "extra_fields") and isinstance(record.extra_fields, dict):
            log_entry.update(record.extra_fields)
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_entry)


def setup_logging() -> logging.Logger:
    logger = logging.getLogger("observability-lab")
    logger.setLevel(logging.INFO)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    logger.handlers.clear()
    logger.addHandler(handler)
    return logger


logger = setup_logging()


def log_with_context(level: str, message: str, **fields) -> None:
    record = logger.makeRecord(
        logger.name,
        getattr(logging, level),
        "(unknown)",
        0,
        message,
        (),
        None,
    )
    record.extra_fields = fields
    logger.handle(record)


@app.before_request
def before_request() -> None:
    request.start_time = time.time()


@app.after_request
def after_request(response):
    duration_ms = round((time.time() - request.start_time) * 1000, 2)
    REQUEST_COUNTER.labels(
        method=request.method,
        endpoint=request.endpoint or "unknown",
        status=str(response.status_code),
    ).inc()
    log_with_context(
        "INFO",
        "request_completed",
        method=request.method,
        path=request.path,
        status_code=response.status_code,
        duration_ms=duration_ms,
        client_ip=request.remote_addr,
    )
    return response


@app.route("/")
def index():
    return jsonify({"service": "observability-lab-app", "status": "running"})


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "observability-lab-app"})


@app.route("/ready")
def ready():
    return jsonify({"status": "ready", "service": "observability-lab-app"})


@app.route("/api/data")
def get_data():
    items = [{"id": i, "value": random.randint(1, 100)} for i in range(5)]
    log_with_context("INFO", "data_fetched", item_count=len(items))
    return jsonify({"items": items})


@app.route("/api/error")
def trigger_error():
    error_type = request.args.get("type", "simulated_error")
    ERROR_COUNTER.labels(error_type=error_type).inc()
    log_with_context(
        "ERROR",
        "simulated_error_triggered",
        error_type=error_type,
        path=request.path,
    )
    return jsonify({"error": "simulated failure", "type": error_type}), 500


@app.route("/api/error/bulk")
def trigger_bulk_errors():
    count = int(request.args.get("count", 10))
    error_type = request.args.get("type", "bulk_simulated_error")
    for _ in range(count):
        ERROR_COUNTER.labels(error_type=error_type).inc()
        log_with_context(
            "ERROR",
            "bulk_simulated_error",
            error_type=error_type,
            batch=True,
        )
    return jsonify({"errors_generated": count, "type": error_type}), 500


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    log_with_context("INFO", "application_starting", port=port)
    app.run(host="0.0.0.0", port=port)
