#!/bin/sh

API_URL="${API_URL:-http://app:8080/api/jobs/import-products}"
MAX_RETRIES="${MAX_RETRIES:-30}"
RETRY_INTERVAL="${RETRY_INTERVAL:-5}"

echo "=== ETL Job Client ==="
echo "API URL: $API_URL"
echo "Waiting for the application to be ready..."

attempt=0
while [ $attempt -lt $MAX_RETRIES ]; do
    health=$(wget -qO- http://app:8080/actuator/health 2>/dev/null | grep -o '"status":"UP"')
    if [ -n "$health" ]; then
        echo "Application is ready!"
        break
    fi
    attempt=$((attempt + 1))
    echo "Attempt $attempt/$MAX_RETRIES - application not ready, retrying in ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
done

if [ $attempt -eq $MAX_RETRIES ]; then
    echo "ERROR: Application did not become ready after $MAX_RETRIES attempts"
    exit 1
fi

echo ""
echo "--- Launching ETL job ---"
RESPONSE=$(wget -qO- --post-data='' --header='Content-Type: application/json' "$API_URL" 2>&1)
echo "Response: $RESPONSE"

echo ""
echo "--- Waiting 5s and launching again to demonstrate tracing with unique traceId ---"
sleep 5

RESPONSE=$(wget -qO- --post-data='' --header='Content-Type: application/json' "$API_URL" 2>&1)
echo "Response: $RESPONSE"

echo ""
echo "=== Client finished ==="
