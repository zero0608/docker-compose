#!/bin/bash
set -e

PUMA_CMD="bundle exec puma -C config/puma.rb"
PUMA_PORT="3000"

log_info() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]: $1"
}

log_error() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR]: $1"
}

start_puma() {
  log_info "Starting Puma on port $PUMA_PORT..."
  $PUMA_CMD >/dev/null 2>&1 &
  PID=$!
  sleep 2  # Allow time for Puma to start

  if pgrep -f puma > /dev/null; then
    log_info "Puma started successfully."
    return 0
  else
    log_error "Puma failed to start."
    return 1
  fi
}

kill_puma_on_port() {
  pkill -9 -f puma || true
}

retry_start_puma() {
  local retries=3
  local attempt=0
  until start_puma; do
    attempt=$((attempt+1))
    if (( attempt > retries )); then
      log_error "Puma failed to start after $attempt attempts. Exiting."
      exit 1
    fi
    log_info "Retrying Puma start ($attempt/$retries)..."
    kill_puma_on_port
    sleep 2
  done
}

check_and_add_gem() {
  GEM_NAME=$1
  if ! bundle show $GEM_NAME >/dev/null 2>&1; then
    # Check if the gem is in the Gemfile to avoid duplicate versions
    if ! grep -q "gem ['\"]$GEM_NAME['\"]" Gemfile; then
      log_info "$GEM_NAME gem not found in Gemfile. Adding it..."
      
      if bundle add $GEM_NAME; then
        log_info "Successfully added $GEM_NAME to the Gemfile."
      else
        log_error "Failed to add $GEM_NAME to the Gemfile."
      fi
    else
      log_info "$GEM_NAME is already specified in the Gemfile, skipping addition."
    fi
  else
    log_info "$GEM_NAME is already installed."
  fi
}

if [ -f Gemfile ]; then
  log_info "Running bundle install..."
  
  check_and_add_gem dotenv-rails
  check_and_add_gem sidekiq
  check_and_add_gem sidekiq-scheduler
  
  bundle install
  kill_puma_on_port

  # Retry starting Puma up to 3 times
  retry_start_puma
else
  log_error "Gemfile not found. Exiting."
  exit 1
fi
