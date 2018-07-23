#!/usr/bin/env bash
# Set AWS_PROFILE environment variable if desired.

SERVICE_NAME=$1

./modify-app-stack.sh update $SERVICE_NAME
