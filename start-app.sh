#!/bin/bash
#
# Main application starter script
#
# This script builds and starts the Docker environment for the TaciaDocs application.
# It allows selecting a backend (js or java) and specifying the content directory.
#
# Usage: ./start-app.sh <frontend_path> <backend_path> <content_path>
# Example: ./start-app.sh ../frontend ../backend-js ../DATA/content

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
if [ "$#" -ne 3 ]; then
    print_error "Usage: $0 <frontend_path> <backend_path> <content_path>"
fi

FRONTEND_PATH=$1
BACKEND_PATH=$2
CONTENT_DIR_PATH=$3

# Validate paths
for path in "$FRONTEND_PATH" "$BACKEND_PATH" "$CONTENT_DIR_PATH"; do
    if [ ! -d "$path" ]; then
        print_error "Directory not found: $path"
    fi
    
    # Convert to absolute path
    if [[ "$OSTYPE" == cygwin* || "$OSTYPE" == msys* || "$OSTYPE" == win32* ]]; then
        path=$(cygpath -w "$(cd "$path" && pwd)")
    else
        path=$(cd "$path" && pwd)
    fi
done

# Validate content directory exists
if [ ! -d "$CONTENT_DIR_PATH" ]; then
    print_error "Content directory not found at: $CONTENT_DIR_PATH"
fi

# --- 1. Environment Cleanup and Setup ---
echo -e "${YELLOW}Cleaning existing Docker resources...${NC}"
./clean-docker.sh

# --- 2. Set Environment Variables ---
print_msg "Setting up environment variables"

# Extract service name from backend path
BACKEND_SERVICE_NAME=$(basename "$BACKEND_PATH")
export BACKEND_SERVICE="$BACKEND_SERVICE_NAME"

# Set content directory path
export CONTENT_DIR_HOST="$CONTENT_DIR_PATH"

echo "Backend Service: $BACKEND_SERVICE"
echo "Frontend Path: $FRONTEND_PATH"
echo "Backend Path: $BACKEND_PATH"
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

# Function to check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    elif docker compose version &> /dev/null; then
        echo "docker compose"
    else
        print_error "Neither 'docker-compose' nor 'docker compose' command found. Please install Docker Compose."
    fi
}

# --- 5. Start Services ---
print_msg "Building and starting services: '$BACKEND_SERVICE' and 'frontend'"
DOCKER_COMPOSE_CMD=$(check_docker_compose)
$DOCKER_COMPOSE_CMD up --build -d "$BACKEND_SERVICE" frontend

# --- 6. Wait for Backend to be Ready ---
print_msg "Waiting for backend service '$BACKEND_SERVICE' to be ready..."

# Health check from testpoint container using service DNS name
check_backend_health() {
    local max_retries=15
    local retry_count=0
    local backend_url="http://$BACKEND_SERVICE:7070"

    until [ $retry_count -ge $max_retries ]; do
        # Try several possible endpoints for robustness
        if $DOCKER_COMPOSE_CMD run --rm testpoint sh -c \
            "curl -sf $backend_url/health || curl -sf $backend_url/api/health || curl -sf $backend_url/" > /dev/null 2>&1; then
            echo "Backend is ready!"
            return 0
        fi
        retry_count=$((retry_count + 1))
        echo "Waiting for backend to be ready... ($retry_count/$max_retries)"
        sleep 2
    done
    return 1
}

if ! check_backend_health; then
    print_error "Backend service failed to start. Check logs with: $DOCKER_COMPOSE_CMD logs $BACKEND_SERVICE"
fi

# --- 8. Final Status ---
print_msg "Detect frontend port from docker-compose.yml"
detect_frontend_port() {
    local port_line
    port_line=$(awk '/frontend:/, /environment:/' docker-compose.yml | grep -E '^\s*-\s*"[0-9]+:' | head -n1)
    if [[ $port_line =~ ([0-9]+): ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "80"
    fi
}
FRONTEND_PORT=$(detect_frontend_port)

echo -e "\n--- All services are up and running! ---"
echo "- Frontend is available at http://localhost:$FRONTEND_PORT"
echo "- Backend ($BACKEND_SERVICE) is running and tested."