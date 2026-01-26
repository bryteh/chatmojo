#!/bin/sh

set -e

# Replace the following line with the correct check for your specific setup if needed
# For Chatwoot/Chatmojo, we need to prepare the database if tables are missing.


# Ensure dependencies are satisfied
bundle check || bundle install

echo "Checking database state..."
# Attempt to run migrations/prepare. If it fails, it usually means the DB isn't reachable yet, 
# but previous steps in Dockerfile handle waiting. 
# This command creates tables if they don't exist.
bundle exec rails db:chatwoot_prepare

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Start the Rails server
exec "$@"
