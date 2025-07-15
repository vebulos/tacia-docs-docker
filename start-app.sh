#!/bin/bash

# This script automates the setup and launch of the Tacia development environment.
# It allows selecting either the JavaScript or Java backend.
# Usage: ./start-app.sh [js|java]

# --- Configuration ---
# Colors for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Exit immediately if a command exits with a non-zero status.
set -e

# Ensure the script runs from its own directory
cd "$(dirname "$0")"

# --- 1. Validate Parameters ---
if [ $# -ne 1 ] || ! [[ "$1" =~ ^(js|java)$ ]]; then
    echo -e "${RED}Error: You must specify which backend to use (js or java).${NC}"
    echo -e "Usage: ./start-app.sh [js|java]"
    exit 1
fi

# --- 2. Set Environment ---
# Export BACKEND_SERVICE so docker-compose.yml can use it.
export BACKEND_SERVICE="backend-$1"
BACKEND_TYPE=$1
echo -e "${GREEN}Selected backend service: $BACKEND_SERVICE${NC}"

# --- 3. Environment Cleanup and Setup ---
echo -e "${YELLOW}Cleaning existing Docker resources...${NC}"
./clean-docker.sh

echo -e "${YELLOW}Creating Docker network 'tacia-net'...${NC}"
# Create network if it doesn't exist, ignore error if it does.
docker network create tacia-net > /dev/null 2>&1 || true

# --- 5. Create .env file for Docker Compose ---
echo "BACKEND_SERVICE=${BACKEND_SERVICE}" > .env

# --- 6. Start Services ---
echo -e "${YELLOW}Building and starting services: '$BACKEND_SERVICE' and 'frontend'...${NC}"
# Build images if they don't exist and start containers in detached mode.
docker compose up --build -d $BACKEND_SERVICE frontend

# --- 6. Wait for Backend Readiness ---
echo -e "${YELLOW}Waiting for backend to be ready...${NC}"
MAX_RETRIES=30
RETRY_DELAY=2
RETRY_COUNT=0

READY_CHECK_CMD=""
if [ "$BACKEND_TYPE" = "js" ]; then
    READY_CHECK_CMD="pgrep node"
elif [ "$BACKEND_TYPE" = "java" ]; then
    # This should be adapted for the actual Java process name
    READY_CHECK_CMD="pgrep java"
fi

until [ $RETRY_COUNT -ge $MAX_RETRIES ]; do
    # Use docker exec to check for the process inside the container
    if docker compose ps -q $BACKEND_SERVICE | xargs -I {} docker exec {} $READY_CHECK_CMD > /dev/null 2>&1; then
        echo -e "${GREEN}Backend is ready!${NC}"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
    echo -e "${YELLOW}Waiting... (attempt $RETRY_COUNT/$MAX_RETRIES)${NC}"
    sleep $RETRY_DELAY
done

if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo -e "${RED}Error: Backend failed to start in time.${NC}"
    docker compose logs $BACKEND_SERVICE
    exit 1
fi

# --- 7. Run Integration Tests ---
echo -e "${YELLOW}Running integration tests...${NC}"
# 'docker compose run' will execute the command from the Dockerfile and then stop the container.
# It inherits the BACKEND_SERVICE variable from this script's environment.
docker compose run --rm testpoint

# --- 8. Final Status ---
echo -e "${GREEN}All services are up and running!${NC}"
echo "- Frontend is available at http://localhost"
echo "- Backend ($BACKEND_SERVICE) is running and tested."
