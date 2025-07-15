# Production stage
FROM node:22-alpine

WORKDIR /app

# Install production dependencies only
COPY backend-js/package*.json ./
RUN if [ -f package-lock.json ]; then \
      npm ci --only=production; \
    else \
      npm install --only=production; \
    fi

# Copy source code
COPY backend-js/ .

# Expose the correct port
EXPOSE 7070

# Command to run the application with correct content-dir
CMD ["node", "server.js", "--port=7070", "--content-dir=/content"]
