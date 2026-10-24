# Stage 1: Build the application
# Use Maven and JDK 17 to match the Java version targeted by the project.
# The Alpine-based image helps reduce the base image footprint.
FROM maven:3.10.0-eclipse-temurin-17-alpine AS build

# Set the working directory for subsequent build instructions.
WORKDIR /app

# Copy the Maven project configuration and dependency definitions.
COPY pom.xml .

# Copy the Java source code required to build the application.
COPY src ./src

# Compile the application and package it into an executable JAR.
RUN mvn -B package


# Stage 2: Run the application
# Use a lightweight JRE image instead of a full JDK for runtime.
FROM eclipse-temurin:17-jre-alpine

# Set the working directory in the runtime image.
WORKDIR /app

# Create a dedicated non-root user and group for the application.
RUN addgroup -S spring && adduser -S spring -G spring

# Copy the packaged JAR from the build stage.
# Build tools and source files are excluded from the final image.
COPY --from=build /app/target/*.jar app.jar

# Run the application as a non-root user.
USER spring

# Document the port used by the application inside the container.
# This does not publish the port on the host; use -p or Compose port mapping.
EXPOSE 8080

# Define the command used to start the Spring Boot application.
ENTRYPOINT ["java", "-jar", "app.jar"]
