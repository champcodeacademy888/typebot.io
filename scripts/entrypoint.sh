#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Check the SCOPE environment variable to decide which application to start
if [ "$SCOPE" = "api" ]; then
  echo "Starting API server..."
  exec bun /app/apps/api/dist/server.js
elif [ -f "/app/${SCOPE}-entrypoint.sh" ]; then
  echo "Executing ${SCOPE}-entrypoint.sh..."
  exec /app/${SCOPE}-entrypoint.sh
else
  echo "Error: Unknown scope or missing entrypoint for '${SCOPE}'"
  exit 1
fi
