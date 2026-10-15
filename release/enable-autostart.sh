#!/usr/bin/env bash

set -euo pipefail

SERVICE_NAME="micropihq"

sudo systemctl enable "$SERVICE_NAME.service"
echo "$SERVICE_NAME autostart enabled."
