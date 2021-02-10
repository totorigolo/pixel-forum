#!/usr/bin/env bash
# Runs database migrations when the container starts.
# See: https://www.thegreatcodeadventure.com/run-ecto-migrations-in-production-distillery/

set +e

echo "Preparing to run migrations"

while true; do
  nodetool ping
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo "Application is up!"
    break
  fi
done

set -e

echo "Creating DB (first time only)"
bin/pixel_forum rpc "Elixir.PixelForum.ReleaseTasks.storage_up"
echo "Creating DB successful"

echo "Running migrations"
bin/pixel_forum rpc "Elixir.PixelForum.ReleaseTasks.migrate"
echo "Migrations run successfully"
