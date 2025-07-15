#!/bin/bash

# Script to clean Docker resources for all services in the docker directory
# Usage: ./clean-docker.sh

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

echo -e "${YELLOW}=== Cleaning Docker resources ===${NC}"

# Get all service names from docker directory
SERVICE_DIRS=$(ls -d */ | sed 's#/##' | grep -E "^(testpoint|backend-js|backend-java|frontend)$")

# 1. Stop and remove containers
echo -e "${YELLOW}Stopping and removing containers...${NC}"
# Get all containers related to our application
CONTAINERS=$(docker ps -a --filter "name=testpoint" --filter "name=backend-js" --filter "name=backend-java" --filter "name=frontend" --format "{{.Names}}")
if [ ! -z "$CONTAINERS" ]; then
    echo -e "${YELLOW}Stopping containers...${NC}"
    docker stop $CONTAINERS 2>/dev/null
    docker rm $CONTAINERS 2>/dev/null
    echo -e "${GREEN}Containers stopped and removed.${NC}"
else
    echo -e "${GREEN}No containers to remove.${NC}"
fi

# 2. Remove volumes
echo -e "${YELLOW}Removing volumes...${NC}"
for dir in $SERVICE_DIRS; do
    VOLUMES=$(docker volume ls -q --filter "name=^${dir}_")
    if [ ! -z "$VOLUMES" ]; then
        echo -e "${YELLOW}Removing volumes for $dir...${NC}"
        echo $VOLUMES | xargs -r docker volume rm 2>/dev/null
        echo -e "${GREEN}Volumes for $dir removed.${NC}"
    else
        echo -e "${GREEN}No volumes for $dir to remove.${NC}"
    fi
done

# 3. Remove network
echo -e "${YELLOW}Removing network...${NC}"
NETWORKS=$(docker network ls --format "{{.Name}}" | grep "_tacia_network")
if [ ! -z "$NETWORKS" ]; then
    echo -e "${YELLOW}Removing networks...${NC}"
    for network in $NETWORKS; do
        docker network rm "$network" 2>/dev/null
        echo -e "${GREEN}Network $network removed.${NC}"
    done
else
    echo -e "${GREEN}No networks to remove.${NC}"
fi

# 4. Remove images
echo -e "${YELLOW}Removing images...${NC}"
for dir in $SERVICE_DIRS; do
    IMAGES=$(docker images -q "*${dir}*" 2>/dev/null)
    if [ ! -z "$IMAGES" ]; then
        echo -e "${YELLOW}Removing images for $dir...${NC}"
        docker rmi -f $IMAGES 2>/dev/null
        echo -e "${GREEN}Images for $dir removed.${NC}"
    else
        echo -e "${GREEN}No images for $dir to remove.${NC}"
    fi
done

echo -e "${GREEN}All Docker resources cleaned.${NC}"
# 5. Clean up dangling resources
echo -e "${YELLOW}Cleaning up dangling resources...${NC}"
docker system prune -f --filter "label=com.docker.compose.project=$PROJECT_NAME" 2>/dev/null
echo -e "${GREEN}Dangling resources cleaned.${NC}"

echo -e "${GREEN}=== Cleanup completed ===${NC}"
