#!/bin/bash

# Script to clean Docker resources for all services in the docker directory
# Usage: ./clean-docker.sh

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

echo -e "${YELLOW}=== Cleaning Docker resources ===${NC}"

# Define the project prefix
PROJECT_PREFIX="tacia"

# 1. Stop and remove containers
echo -e "${YELLOW}Stopping and removing containers...${NC}"
# Get all containers related to our project using the prefix
CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -E "^${PROJECT_PREFIX}[-_]")
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
VOLUMES=$(docker volume ls -q | grep -E "^${PROJECT_PREFIX}[-_]")
if [ ! -z "$VOLUMES" ]; then
    echo -e "${YELLOW}Removing volumes...${NC}"
    echo $VOLUMES | xargs -r docker volume rm 2>/dev/null
    echo -e "${GREEN}Volumes removed.${NC}"
else
    echo -e "${GREEN}No volumes to remove.${NC}"
fi

# 3. Remove network
echo -e "${YELLOW}Removing networks...${NC}"
NETWORKS=$(docker network ls --format "{{.Name}}" | grep -E "^${PROJECT_PREFIX}[-_]")
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
IMAGES=$(docker images --format "{{.Repository}} {{.ID}}" | grep -E "^${PROJECT_PREFIX}[-_]" | awk '{print $2}' | sort -u)
if [ ! -z "$IMAGES" ]; then
    echo -e "${YELLOW}Removing images...${NC}"
    docker rmi -f $IMAGES 2>/dev/null || true
    echo -e "${GREEN}Images removed.${NC}"
else
    echo -e "${GREEN}No images to remove.${NC}"
fi

echo -e "${GREEN}All Docker resources cleaned.${NC}"
# 5. Clean up dangling resources
echo -e "${YELLOW}Cleaning up dangling resources...${NC}"
docker system prune -f --filter "label=com.docker.compose.project=${PROJECT_PREFIX}" 2>/dev/null
echo -e "${GREEN}Dangling resources cleaned.${NC}"

# 6. Remove Docker build cache
echo -e "${YELLOW}Cleaning Docker build cache...${NC}"
docker builder prune -af 2>/dev/null

# 7. Remove all Docker buildx builders
echo -e "${YELLOW}Removing all Docker buildx builders...${NC}"
BUILDERS=$(docker buildx ls | awk 'NR>1 {print $1}')
if [ ! -z "$BUILDERS" ]; then
    for builder in $BUILDERS; do
        docker buildx rm -f "$builder" 2>/dev/null || true
    done
    echo -e "${GREEN}All buildx builders removed.${NC}"
else
    echo -e "${GREEN}No buildx builders to remove.${NC}"
fi

echo -e "${GREEN}=== Cleanup completed ===${NC}"
