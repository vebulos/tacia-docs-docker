FROM alpine:3.20

# Install dependencies
RUN apk add --no-cache bash curl

# Copy test script
COPY test-backend-endpoints.sh /app/

# Set working directory
WORKDIR /app

# Default command
CMD ["bash"]
