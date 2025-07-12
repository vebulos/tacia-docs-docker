#!/bin/bash

# Script to clean Docker resources for the current project
# Usage: ./clean-docker.sh

# Get the current directory name as project name
PROJECT_NAME=$(basename $(pwd) | tr '[:upper:]' '[:lower:]')
NETWORK_NAME="${PROJECT_NAME}_mxc_network"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Cleaning Docker resources for ${PROJECT_NAME} ===${NC}"

# 1. Stop and remove containers
echo -e "${YELLOW}Stopping and removing containers...${NC}"
CONTAINERS=$(docker ps -a --filter "name=^/${PROJECT_NAME}_" --format "{{.Names}}")
if [ ! -z "$CONTAINERS" ]; then
    docker stop $CONTAINERS 2>/dev/null
    docker rm $CONTAINERS 2>/dev/null
    echo -e "${GREEN}Containers stopped and removed.${NC}"
else
    echo -e "${GREEN}No containers to remove.${NC}"
fi

# 2. Remove volumes
echo -e "${YELLOW}Removing volumes...${NC}"
VOLUMES=$(docker volume ls -q --filter "name=^${PROJECT_NAME}_")
if [ ! -z "$VOLUMES" ]; then
    echo $VOLUMES | xargs -r docker volume rm 2>/dev/null
    echo -e "${GREEN}Volumes removed.${NC}"
else
    echo -e "${GREEN}No volumes to remove.${NC}"
fi

# 3. Remove network
echo -e "${YELLOW}Removing network...${NC}"
if docker network inspect "$NETWORK_NAME" &>/dev/null; then
    docker network rm "$NETWORK_NAME" 2>/dev/null
    echo -e "${GREEN}Network removed.${NC}"
else
    echo -e "${GREEN}Network does not exist.${NC}"
fi

# 4. Remove images
echo -e "${YELLOW}Removing images...${NC}"
IMAGES=$(docker images -q "*${PROJECT_NAME}*" 2>/dev/null)
if [ ! -z "$IMAGES" ]; then
    docker rmi -f $IMAGES 2>/dev/null
    echo -e "${GREEN}Images removed.${NC}"
else
    echo -e "${GREEN}No images to remove.${NC}"
fi

# 5. Clean up dangling resources
echo -e "${YELLOW}Cleaning up dangling resources...${NC}"
docker system prune -f --filter "label=com.docker.compose.project=$PROJECT_NAME" 2>/dev/null
echo -e "${GREEN}Dangling resources cleaned.${NC}"

echo -e "${GREEN}=== Cleanup completed ===${NC}"
