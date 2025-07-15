#!/bin/bash
#
# Main application starter script
#
# This script builds and starts the Docker environment for the TaciaDocs application.
# It allows selecting a backend (js or java) and specifying the content directory.
#
# Usage: ./start-app.sh [js|java] <path_to_content_directory>
# Example: ./start-app.sh js ../DATA/content

# --- Configuration & Setup ---
# Strict mode: exit on error, undefined variable, or pipe failure
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Ensure the script runs from its own directory for consistent paths
cd "$(dirname "$0")"

# --- Functions ---

# Function to print informational messages
print_msg() {
    echo -e "\n${GREEN}--- $1 ---${NC}"
}

# Function to print error messages and exit
print_error() {
    echo -e "\n${RED}Error: $1${NC}" >&2
    exit 1
}

# --- 0. Validate Script Arguments ---
if [ "$#" -ne 2 ]; then
    print_error "Usage: $0 [js|java] <path_to_content_directory>"
fi

BACKEND_TYPE=$1
CONTENT_DIR_PATH=$2

# Validate backend service type
if [ "$BACKEND_TYPE" != "js" ] && [ "$BACKEND_TYPE" != "java" ]; then
    print_error "Invalid backend service specified. Use 'js' or 'java'."
fi

# Validate content directory exists
if [ ! -d "$CONTENT_DIR_PATH" ]; then
    print_error "Content directory not found at: $CONTENT_DIR_PATH"
fi

# --- 1. Environment Cleanup and Setup ---
echo -e "${YELLOW}Cleaning existing Docker resources...${NC}"
./clean-docker.sh

# --- 2. Set Environment Variables ---
print_msg "Setting up environment variables"
export BACKEND_SERVICE="backend-$BACKEND_TYPE"
# Resolve the absolute path for the content directory to avoid issues with Docker volumes

if [[ "$OSTYPE" == cygwin* || "$OSTYPE" == msys* || "$OSTYPE" == win32* ]]; then
    # Use cygpath to convert to Windows path
    CONTENT_DIR_HOST_WIN=$(cygpath -w "$CONTENT_DIR_PATH")
    export CONTENT_DIR_HOST="$CONTENT_DIR_HOST_WIN"
else
    export CONTENT_DIR_HOST=$(cd "$CONTENT_DIR_PATH" && pwd)
fi

echo "Backend Service: $BACKEND_SERVICE"
echo "Content Directory (Host): $CONTENT_DIR_HOST"

# --- 3. Create Docker Network ---
print_msg "Ensuring Docker network 'tacia-net' exists"
docker network create tacia-net > /dev/null 2>&1 || true

# --- 4. Create .env file for Docker Compose ---
print_msg "Creating .env file for Docker Compose"
# This is the most reliable way to pass variables to docker-compose
cat << EOF > .env
BACKEND_SERVICE=${BACKEND_SERVICE}
CONTENT_DIR_HOST=${CONTENT_DIR_HOST}
EOF

# --- 5. Start Services ---
print_msg "Building and starting services: '$BACKEND_SERVICE' and 'frontend'"
docker-compose up --build -d "$BACKEND_SERVICE" frontend

# --- 6. Wait for Backend to be Ready ---
print_msg "Waiting for backend service '$BACKEND_SERVICE' to be ready..."
WAIT_COMMAND="docker-compose exec $BACKEND_SERVICE"
# For Java, we check for the running java process. For JS, the node process.
if [ "$BACKEND_TYPE" = "java" ]; then
    CHECK_CMD="ps -ef | grep 'java -jar app.jar' | grep -v grep"
else
    CHECK_CMD="ps -ef | grep 'node server.js' | grep -v grep"
fi

# Wait for up to 30 seconds
for i in {1..15}; do
    if $WAIT_COMMAND $CHECK_CMD > /dev/null 2>&1; then
        echo "Backend is ready!"
        break
    fi
    echo "Waiting... ($i)"
    sleep 2
done

if ! $WAIT_COMMAND $CHECK_CMD > /dev/null 2>&1; then
    print_error "Backend service failed to start. Check logs with: docker-compose logs $BACKEND_SERVICE"
fi

# --- 7. Run Integration Tests ---
print_msg "Starting backend endpoint tests"
docker-compose run --rm testpoint

# --- 8. Final Status ---
print_msg "All services are up and running!"
echo -e "- Frontend is available at ${YELLOW}http://localhost${NC}"
echo -e "- Backend ($BACKEND_SERVICE) is running and tested."