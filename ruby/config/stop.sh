#!/bin/bash

log_info() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO]: $1"
}

log_error() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR]: $1"
}

log_info "Stopping Puma..."

if pkill -9 -f puma; then
  log_info "Puma has been stopped successfully."
else
  log_error "Failed to stop Puma or Puma is not running."
fi
