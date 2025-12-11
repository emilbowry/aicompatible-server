# # ----------------------------------
# # STAGE 1: Builder (Builds the App)
# # ----------------------------------
# FROM node:20-alpine AS builder

# # Install OpenSSL (Required for Prisma Client on Alpine)
# RUN apk add --no-cache openssl

# WORKDIR /app

# # Copy config files
# COPY package*.json ./
# COPY tsconfig.json ./
# COPY prisma ./prisma/

# # Install ALL dependencies (including TypeScript, etc.)
# RUN npm ci

# # Copy source code
# COPY src ./src

# # 1. Generate Prisma Client (Output goes to src/generated based on your schema)
# RUN npx prisma generate

# # 2. Run your custom build script
# # This compiles TS and copies assets + src/generated to dist/
# RUN npm run build

# # ----------------------------------
# # STAGE 2: Runner (Production Image)
# # ----------------------------------
# FROM node:20-alpine AS runner

# # Install OpenSSL (Required for Prisma Client on Alpine)
# RUN apk add --no-cache openssl

# ENV NODE_ENV=production
# WORKDIR /app

# # Copy package.json for runtime dependencies
# COPY package*.json ./

# # Install ONLY production dependencies (No TypeScript, No DevTools)
# RUN npm ci --only=production

# # Copy the compiled application (dist) from the builder stage
# COPY --from=builder /app/dist ./dist

# # Expose the port defined in your config
# EXPOSE 7878

# # Start the server
# CMD ["node", "dist/server.js"]

# ----------------------------------
# STAGE 1: Builder (Builds the App)
# ----------------------------------
# Using the current official Node.js LTS (v22) on Alpine
FROM node:22-alpine AS builder

# Install OpenSSL (Required for Prisma Client on Alpine)
RUN apk add --no-cache openssl

WORKDIR /app

# Copy config files
COPY package*.json ./
COPY tsconfig.json ./
# PRISMA IS NOW IN THE ROOT
COPY prisma ./prisma/ 
COPY src ./src

# Install ALL dependencies (including TypeScript, etc.)
RUN npm ci

# 1. Generate Prisma Client
RUN npx prisma generate

# 2. Run your custom build script
RUN npm run build

# ----------------------------------
# STAGE 2: Runner (Production Image)
# ----------------------------------
# Using the current official Node.js LTS (v22) on Alpine
FROM node:22-alpine AS runner

# Install OpenSSL (Required for Prisma Client on Alpine)
RUN apk add --no-cache openssl

ENV NODE_ENV=production
WORKDIR /app

# Copy package.json for runtime dependencies
COPY package*.json ./

# Install ONLY production dependencies (minimal image size)
RUN npm ci --only=production

# Copy compiled app and necessary artifacts from the builder stage
COPY --from=builder /app/dist ./dist
# Copy the generated Prisma client and engine (required for runtime)
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/prisma ./prisma

# Expose the port defined in your config
EXPOSE 7878

# Start the server
CMD ["node", "dist/server.js"]