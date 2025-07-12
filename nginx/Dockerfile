# Simple Nginx server for static files
FROM nginx:alpine

# Copy custom nginx config
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf

# The frontend files will be mounted as a volume in docker-compose.yml
# This creates an empty directory that will be overridden by the volume mount
RUN mkdir -p /usr/share/nginx/html

# Expose ports
EXPOSE 80
EXPOSE 443

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
