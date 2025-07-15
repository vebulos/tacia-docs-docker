FROM alpine:3.20

# Install dependencies
# Install bash for scripting, curl for requests, and GNU grep for full regex support
RUN apk add --no-cache bash curl grep

# Copy test script
COPY test-backend-endpoints.sh /app/

# Make the script executable
RUN chmod +x /app/test-backend-endpoints.sh

# Set working directory
WORKDIR /app

# Environment variable will be set via docker-compose

# Default command
CMD ["/app/test-backend-endpoints.sh"]
