#!/bin/bash
# start_server.sh - Script to start the Python application
# Used by AWS CodeDeploy during the ApplicationStart lifecycle hook

set -e

APP_DIR="/home/ubuntu/app"
LOG_DIR="/var/log/simple-python-app"
PID_FILE="/var/run/simple-python-app.pid"

# Create log directory if it doesn't exist
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    echo "Created log directory: $LOG_DIR"
fi

# Navigate to the application directory
cd "$APP_DIR" || {
    echo "ERROR: Application directory $APP_DIR not found"
    exit 1
}

# Check if virtual environment exists
if [ -d "venv" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
fi

# Check if the app is already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Application is already running with PID $OLD_PID. Stopping it first..."
        kill "$OLD_PID"
        sleep 2
    fi
    rm -f "$PID_FILE"
fi

echo "Starting simple-python-app..."

# Start the Flask application in the background
nohup python3 app.py \
    >> "$LOG_DIR/app.log" 2>> "$LOG_DIR/error.log" &

APP_PID=$!
echo "$APP_PID" > "$PID_FILE"

# Wait briefly and verify the process started successfully
sleep 3
if kill -0 "$APP_PID" 2>/dev/null; then
    echo "Application started successfully with PID $APP_PID"
else
    echo "ERROR: Application failed to start. Check logs at $LOG_DIR/error.log"
    cat "$LOG_DIR/error.log"
    exit 1
fi

echo "start_server.sh completed successfully"
