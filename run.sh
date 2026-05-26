#!/bin/bash
set -e

CONFIG="config.dev.json"

if [ ! -f "$CONFIG" ]; then
  echo "Error: $CONFIG not found."
  echo "Create it with your API keys:"
  echo '{"REVENUECAT_API_KEY":"...","OPENROUTER_API_KEY":"..."}'
  exit 1
fi

exec flutter run --dart-define-from-file="$CONFIG" "$@"
