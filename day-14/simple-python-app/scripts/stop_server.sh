#!/bin/bash

# stop_server.sh - Script to stop the running Python application
# Used by AWS CodeDeploy during the ApplicationStop lifecycle event

APP_NAME="simple-python-app"
PID_FILE="/var/run/${APP_NAME}.pid"
LOG_FILE="/var/log/${APP_NAME}/deploy.log"

# Ensure log directory exists
mkdir -p /var/log/${APP_NAME}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "Starting stop_server.sh"

# Stop using PID file if it exists
if [ -f "${PID_FILE}" ]; then
    PID=$(cat "${PID_FILE}")
    if kill -0 "${PID}" 2>/dev/null; then
        log "Stopping ${APP_NAME} with PID ${PID}"
        kill -SIGTERM "${PID}"

        # Wait up to 10 seconds for graceful shutdown
        for i in $(seq 1 10); do
            if ! kill -0 "${PID}" 2>/dev/null; then
                log "${APP_NAME} stopped gracefully."
                break
            fi
            sleep 1
        done

        # Force kill if still running
        if kill -0 "${PID}" 2>/dev/null; then
            log "Force killing ${APP_NAME} with PID ${PID}"
            kill -SIGKILL "${PID}"
        fi
    else
        log "PID ${PID} not found. Process may have already stopped."
    fi

    rm -f "${PID_FILE}"
else
    log "PID file not found. Attempting to find process by name."
fi

# Fallback: kill by process name/port
PORT=5000
PORT_PID=$(lsof -t -i:${PORT} 2>/dev/null)

if [ -n "${PORT_PID}" ]; then
    log "Found process on port ${PORT} with PID ${PORT_PID}. Stopping it."
    kill -SIGTERM "${PORT_PID}" 2>/dev/null
    sleep 2
    if kill -0 "${PORT_PID}" 2>/dev/null; then
        kill -SIGKILL "${PORT_PID}" 2>/dev/null
    fi
    log "Process on port ${PORT} stopped."
else
    log "No process found on port ${PORT}."
fi

log "stop_server.sh completed."
exit 0
