#!/usr/bin/env bash

set -euo pipefail

SERVICE_NAME="micropihq"

sudo systemctl stop "$SERVICE_NAME"
echo "$SERVICE_NAME stopped."
