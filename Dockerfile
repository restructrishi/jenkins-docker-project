# ---- Base Stage ----
# Use an official Node.js runtime as a parent image
FROM node:18-alpine AS base
WORKDIR /app

# ---- Dependencies Stage ----
# Install dependencies in a separate layer to leverage Docker's cache
FROM base AS dependencies
COPY package*.json ./
RUN npm ci

# ---- Build Stage ----
# This stage is for projects that need a build step (e.g., TypeScript, React).
# Your project doesn't seem to need it, but it's good practice to keep it.
FROM dependencies AS build
COPY . .
# If you had a build script, you would run it here:
# RUN npm run build

# ---- Production Stage ----
# Create a final, smaller image for production
FROM base AS production
ENV NODE_ENV=production
# Copy only the necessary production dependencies
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/package*.json ./
# Copy your application code
COPY . .

# Your app binds to port 3000 (or whatever your app.js uses)
EXPOSE 3000

# Command to run your app (CORRECTED LINE)
CMD [ "node", "app.js" ]