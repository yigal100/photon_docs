FROM node:22-slim AS builder

# Install pnpm
RUN npm install -g pnpm

WORKDIR /usr/src/app

# Copy package files
COPY package.json pnpm-lock.yaml* pnpm-workspace.yaml* ./

# Install dependencies
RUN pnpm install --frozen-lockfile

FROM node:22-slim

# Install pnpm in runtime image
RUN npm install -g pnpm

WORKDIR /usr/src/app

# Copy node_modules from builder stage
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Copy application code
COPY . .

# Expose port
EXPOSE 8080

# Start the application
CMD ["pnpm", "run", "quartz", "build", "--serve"]
