#!/bin/bash

# Exit on error
set -e

# Load environment variables
set -a
source .env
set +a

# Function to stop and remove a specific container
stop_container() {
    echo "Stopping $1..."
    docker compose stop $1 2>/dev/null || true
    docker compose rm -f $1 2>/dev/null || true
}

# Stop and remove all services to ensure clean state
echo "Stopping all services..."
docker compose down

# Start the selected backend
echo "Starting $ACTIVE_BACKEND backend..."
if [ "$ACTIVE_BACKEND" = "js" ]; then
    # Start only JS backend
    echo "Starting JS backend..."
    docker compose --profile backend-js up -d --build backend-js
    
    # Start Nginx after the backend is up
    echo "Starting Nginx..."
    docker compose up -d nginx
    
    # Wait for backend to be healthy
    echo "Waiting for backend to be ready..."
    max_attempts=15
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        # Show container logs on first attempt
        if [ $attempt -eq 1 ]; then
            echo "Container logs (last 10 lines):"
            docker compose logs --tail=10 backend-js
        fi
        
        # Check if container is running
        container_status=$(docker compose ps -q backend-js | xargs -I {} docker inspect -f '{{.State.Status}}' {} 2>/dev/null || echo "not running")
        if [ "$container_status" != "running" ]; then
            echo "Container is not running. Current status: $container_status"
            docker compose logs backend-js
            exit 1
        fi
        
        # Try to access the health endpoint
        if curl -s -f http://localhost:${BACKEND_PORT}/health > /dev/null; then
            echo "Backend JS is up and running!"
            break
        fi
        
        echo "Waiting for backend to start (attempt $attempt/$max_attempts)..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "Error: Backend JS failed to start after $max_attempts attempts"
        echo "Last logs:"
        docker compose logs backend-js
        exit 1
    fi
else
    # Start only Java backend
    echo "Starting Java backend..."
    docker compose --profile backend-java up -d --build backend-java
    
    # Start Nginx after the backend is up
    echo "Starting Nginx..."
    docker compose up -d nginx
    
    # Wait for backend to be healthy
    echo "Waiting for backend to be ready..."
    max_attempts=30  # Java might take longer to start
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        # Show container logs on first attempt and every 5 attempts
        if [ $attempt -eq 1 ] || [ $((attempt % 5)) -eq 0 ]; then
            echo "Container logs (last 10 lines):"
            docker compose logs --tail=10 backend-java
        fi
        
        # Check if container is running
        container_status=$(docker compose ps -q backend-java | xargs -I {} docker inspect -f '{{.State.Status}}' {} 2>/dev/null || echo "not running")
        if [ "$container_status" != "running" ]; then
            echo "Container is not running. Current status: $container_status"
            docker compose logs backend-java
            exit 1
        fi
        
        # Try to access the health endpoint
        if curl -s -f http://localhost:${BACKEND_PORT}/actuator/health > /dev/null; then
            echo "Backend Java is up and running!"
            break
        fi
        
        echo "Waiting for backend to start (attempt $attempt/$max_attempts)..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "Error: Backend Java failed to start after $max_attempts attempts"
        echo "Last logs:"
        docker compose logs backend-java
        exit 1
    fi
fi

# Show status
echo -e "\n=== Running Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Get the container IP for the backend
if [ "$ACTIVE_BACKEND" = "js" ]; then
    echo -e "\nBackend JS is running on port ${BACKEND_PORT}"
    echo "Health check: curl http://localhost:${BACKEND_PORT}/health"
else
    echo -e "\nBackend Java is running on port ${BACKEND_PORT}"
    echo "Health check: curl http://localhost:${BACKEND_PORT}/actuator/health"
fi
echo -e "\nNginx is proxying requests to http://localhost:80 -> http://localhost:${BACKEND_PORT}"
echo -e "\nTo view logs: docker compose logs -f"
