FROM swift:6.0-slim AS build

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy package files
COPY Package.swift Package.resolved ./

# Resolve dependencies
RUN swift package resolve

# Copy source code
COPY Sources ./Sources

# Build the application
RUN swift build -c release

# Create runtime image
FROM swift:6.0-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl1.1 \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy built executable
COPY --from=build /app/.build/release/NotificationService /app/

# Expose port
EXPOSE 8004

# Run the app
ENTRYPOINT ["./NotificationService"]
