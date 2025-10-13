# Use an official Node.js runtime as the base image
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install the application dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose port 3000 to the outside world
EXPOSE 3000

# Command to run the application
CMD ["node", "app.js"]


FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/my-java-app-1.0.0.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
