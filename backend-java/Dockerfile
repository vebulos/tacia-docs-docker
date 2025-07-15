# Build stage
FROM maven:3.9.6-eclipse-temurin-21 AS build

WORKDIR /app

# Copy the POM file and download dependencies
COPY backend-java/pom.xml .
RUN mvn dependency:go-offline -B

# Copy the rest of the source code
COPY backend-java/ .

# Build the application
RUN mvn package -DskipTests

# Production stage
FROM eclipse-temurin:21-jre

WORKDIR /app

# Copy the JAR file from the build stage
COPY --from=build /app/target/*.jar app.jar

# Create necessary directories
RUN mkdir -p /app/data/content

# Expose port
EXPOSE 7070

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
