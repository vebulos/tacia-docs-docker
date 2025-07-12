# Development stage
FROM node:22-alpine AS development

WORKDIR /app

# Install dependencies
COPY backend-js/package*.json ./
RUN if [ -f package-lock.json ]; then \
      npm ci; \
    else \
      npm install; \
    fi

# Copy source code
COPY backend-js/ .

# Expose port
EXPOSE 4201 

# Command to run the application
CMD ["npm", "run", "start"]

# Production stage
FROM node:22-alpine AS production

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

# Create necessary directories
RUN mkdir -p /app/data/content

# Expose port
EXPOSE 4201

# Command to run the application
CMD ["node", "server.js"]
