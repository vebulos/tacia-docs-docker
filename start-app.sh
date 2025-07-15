#!/bin/bash

# Script to start the application with chosen backend
# Usage: ./start-app.sh [js|java]

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get project name from current directory
PROJECT_NAME=$(basename $(pwd) | tr '[:upper:]' '[:lower:]')
NETWORK_NAME="${PROJECT_NAME}_tacia_network"

# Check if backend is specified
case "$1" in
    js)
        BACKEND_DIR="../backend-js"
        BACKEND_DOCKER="backend-js"
        ;;
    java)
        BACKEND_DIR="../backend-java"
        BACKEND_DOCKER="backend-java"
        ;;
    *)
        echo -e "${RED}Error: Invalid backend specified${NC}"
        exit 1
        ;;
esac

# 1. Clean existing Docker resources
echo -e "${YELLOW}Cleaning existing Docker resources...${NC}"
./clean-docker.sh

# 2. Create Docker network
echo -e "${YELLOW}Creating Docker network...${NC}"
docker network create tacia-net 2>/dev/null

# 3. Build and run testpoint
echo -e "${YELLOW}Building and running testpoint...${NC}"
docker compose build testpoint
docker compose up -d testpoint

# 4. Build and run backend
echo -e "${YELLOW}Building and running backend...${NC}"
if [ "$1" = "js" ]; then
    BACKEND_SERVICE="backend-js"
    BACKEND_PORT=7070
    BACKEND_IMAGE="backend-js"
    echo -e "${YELLOW}Using JavaScript backend${NC}"
else
    BACKEND_SERVICE="backend-java"
    BACKEND_PORT=7070
    BACKEND_IMAGE="backend-java"
    echo -e "${YELLOW}Using Java backend${NC}"
fi

docker compose build $BACKEND_SERVICE
docker compose up -d $BACKEND_SERVICE

# 5. Wait for backend to be ready
echo -e "${YELLOW}Waiting for backend to be ready...${NC}"
MAX_RETRIES=30
RETRY_DELAY=2

for ((i=1; i<=MAX_RETRIES; i++)); do
    echo -e "${YELLOW}Attempt $i of $MAX_RETRIES...${NC}"
    # Check if the node process is running
    if docker compose exec $BACKEND_SERVICE ps aux | grep -q "node server.js"; then
        echo -e "${GREEN}Backend is running!${NC}"
        break
    fi
    sleep $RETRY_DELAY
    if [ $i -eq $MAX_RETRIES ]; then
        echo -e "${RED}Backend failed to start after $MAX_RETRIES attempts${NC}"
        exit 1
    fi
done

# 6. Run backend tests
echo -e "${YELLOW}Running backend tests...${NC}"
docker compose exec testpoint bash -c "cd /testpoint && ./test-backend-endpoints.sh http://localhost:7070"

# 7. Build and run frontend
echo -e "${YELLOW}Building and running frontend...${NC}"
docker compose build frontend
docker compose up -d frontend

# 8. Build and run nginx
echo -e "${YELLOW}Building and running nginx...${NC}"
docker compose build nginx
docker compose up -d nginx

# 8. Test nginx
echo -e "${YELLOW}=== Testing nginx ===${NC}"
# Add your nginx tests here
echo -e "${GREEN}All services started successfully!${NC}"
