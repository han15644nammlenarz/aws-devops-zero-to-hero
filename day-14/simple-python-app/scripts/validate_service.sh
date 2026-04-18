#!/bin/bash

# validate_service.sh
# This script validates that the application is running correctly
# after deployment. Used by AWS CodeDeploy ValidateService hook.

set -e

APP_PORT=5000
APP_HOST="localhost"
HEALTH_ENDPOINT="http://${APP_HOST}:${APP_PORT}/health"
MAX_RETRIES=10
RETRY_INTERVAL=5

echo "[$(date)] Starting service validation..."

# Check if the application process is running
check_process() {
    if pgrep -f "python.*app.py" > /dev/null 2>&1; then
        echo "[$(date)] Application process is running."
        return 0
    else
        echo "[$(date)] ERROR: Application process is NOT running."
        return 1
    fi
}

# Check if the application responds on the health endpoint
check_health_endpoint() {
    local retries=0

    while [ $retries -lt $MAX_RETRIES ]; do
        echo "[$(date)] Checking health endpoint (attempt $((retries + 1))/$MAX_RETRIES)..."

        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${HEALTH_ENDPOINT}" 2>/dev/null || echo "000")

        if [ "$HTTP_STATUS" -eq 200 ]; then
            echo "[$(date)] Health endpoint returned HTTP 200. Service is healthy."
            return 0
        else
            echo "[$(date)] Health endpoint returned HTTP ${HTTP_STATUS}. Retrying in ${RETRY_INTERVAL}s..."
            retries=$((retries + 1))
            sleep $RETRY_INTERVAL
        fi
    done

    echo "[$(date)] ERROR: Health endpoint did not return 200 after ${MAX_RETRIES} attempts."
    return 1
}

# Check if the main endpoint responds
check_main_endpoint() {
    local url="http://${APP_HOST}:${APP_PORT}/"
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null || echo "000")

    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo "[$(date)] Main endpoint returned HTTP 200."
        return 0
    else
        echo "[$(date)] WARNING: Main endpoint returned HTTP ${HTTP_STATUS}."
        return 1
    fi
}

# Run all validation checks
main() {
    echo "[$(date)] ===== Service Validation Started ====="

    check_process || exit 1
    check_health_endpoint || exit 1
    check_main_endpoint || exit 1

    echo "[$(date)] ===== Service Validation Passed ====="
    exit 0
}

main
