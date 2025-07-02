#!/bin/bash

# Migration/init script for BookSwap Hub PostgreSQL database
# Usage: ./migrate.sh [ENV_FILE]
# Assumes either environment variables present or you can set them in ENV_FILE (default: ./db_visualizer/postgres.env)
set -e

ENV_FILE="${1:-./db_visualizer/postgres.env}"

if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from $ENV_FILE"
  set -o allexport
  source "$ENV_FILE"
  set +o allexport
fi

if [ -z "$POSTGRES_URL" ]; then
  echo "POSTGRES_URL not set. Please ensure env vars are loaded, or set the database connection string prior to running."
  exit 1
fi

echo "Running schema migration with psql..."

psql "$POSTGRES_URL" -v ON_ERROR_STOP=1 -f "$(dirname "$0")/init.sql"

echo "Migration complete. Schema is up to date."
