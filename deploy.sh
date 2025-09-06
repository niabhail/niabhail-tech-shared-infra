#!/bin/bash

# Deployment script for niabhail-tech shared infrastructure
# This creates the foundation that all other services depend on
#
# Usage: ./deploy.sh [domain]
# Examples:
#   ./deploy.sh niabhail.tech    # Creates Caddyfile from template
#   ./deploy.sh                  # Uses existing Caddyfile

set -e

echo "🚀 Deploying shared infrastructure..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
   print_warning "Running as root. Consider using a non-root user with sudo privileges."
fi

print_step "1️⃣  Checking prerequisites..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_status "✅ Docker and Docker Compose are available"

print_step "2️⃣  Handling Caddyfile configuration..."

# Handle Caddyfile creation/validation
if [ -f "Caddyfile" ]; then
    print_status "Using existing Caddyfile"
elif [ -n "$1" ]; then
    print_status "Creating Caddyfile from template with domain: $1"
    if [ ! -f "Caddyfile.template" ]; then
        print_error "Caddyfile.template not found"
        exit 1
    fi
    # Replace {{DOMAIN}} with provided domain
    sed "s/{{DOMAIN}}/$1/g" Caddyfile.template > Caddyfile
    print_status "✅ Caddyfile created successfully"
else
    print_error "No Caddyfile found and no domain provided"
    echo ""
    echo "Options:"
    echo "1. Run: ./deploy.sh <domain> (creates Caddyfile from template)"
    echo "   Example: ./deploy.sh niabhail.tech"
    echo "2. Manually copy Caddyfile.template to Caddyfile and edit"
    echo ""
    exit 1
fi

print_step "3️⃣  Creating directories..."

# Create logs directory
mkdir -p logs
print_status "Created logs directory"

print_step "4️⃣  Deploying Caddy infrastructure..."

# Stop existing containers if running
print_status "Stopping any existing containers..."
docker compose down 2>/dev/null || true

# Remove any existing niabhail-tech-network to ensure clean state
print_status "Cleaning up existing network..."
docker network rm niabhail-tech-network 2>/dev/null || true

# Deploy the infrastructure
print_status "Starting shared infrastructure..."
docker compose up -d

print_step "5️⃣  Verifying deployment..."

# Wait a moment for containers to start
sleep 5

# Check if Caddy is running
if docker ps | grep -q shared-caddy; then
    print_status "✅ Caddy is running successfully"
else
    print_error "❌ Caddy failed to start. Checking logs..."
    docker compose logs
    exit 1
fi

# Check if niabhail-tech-network exists
if docker network ls | grep -q niabhail-tech-network; then
    print_status "✅ niabhail-tech-network created successfully"
else
    print_error "❌ niabhail-tech-network not found"
    exit 1
fi

# Test Caddy health endpoint
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    print_status "✅ Caddy health check passed"
else
    print_warning "⚠️ Caddy health check failed (this might be normal if port 8080 is disabled)"
fi

print_step "🎉 Shared infrastructure deployment complete!"

echo ""
print_status "Infrastructure Status:"
echo "- Caddy proxy: Running on ports 80/443"
echo "- Health check: Available on port 8080"
echo "- Network: niabhail-tech-network created"
echo "- Logs: ./logs/ directory"

echo ""
print_warning "Next Steps:"
echo "1. Verify your domains point to this server's IP address"
echo "2. Deploy your application services (n8n, portfolio site, etc.)"
echo "3. Check logs with: docker compose logs -f"
echo "4. Monitor with: docker ps"

echo ""
print_status "Application services can now connect to 'niabhail-tech-network' and be routed by Caddy"

# Show running containers
echo ""
print_status "Currently running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"