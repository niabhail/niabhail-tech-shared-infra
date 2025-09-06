# niabhail-tech-shared-infra

Shared infrastructure for the niabhail.tech ecosystem. This project provides the foundational services that other projects depend on, including the Caddy reverse proxy and shared Docker network.

## Architecture

This infrastructure follows a clean separation pattern:
- **niabhail-tech-shared-infra** (this project): Foundation services
- **niabhail-tech-site**: Portfolio website
- **n8n-docker**: Automation platform

No application projects have cross-dependencies - they only depend on this shared infrastructure.

## Services

### Caddy Reverse Proxy
- **Container**: `shared-caddy`
- **Ports**: 80 (HTTP), 443 (HTTPS)
- **Network**: `niabhail-tech-network`
- **Features**:
  - Automatic HTTPS with Let's Encrypt
  - HTTP/2 and gzip compression
  - Security headers
  - Static asset caching
  - Request logging

### Docker Network
- **Name**: `niabhail-tech-network`
- **Type**: Bridge network
- **Purpose**: Allows application containers to communicate with Caddy

## Quick Start

### 1. Configure Caddy
Copy the template and customize for your environment:
```bash
cp Caddyfile.template Caddyfile
```

Edit `Caddyfile` and replace template variables:
- `{{DOMAIN}}` - Your main domain (e.g., niabhail.tech)

### 2. Deploy Infrastructure
```bash
chmod +x deploy.sh
./deploy.sh
```

### 3. Verify Deployment
```bash
# Check running containers
docker ps

# Test health endpoint
curl http://localhost:8080/health

# View logs
docker compose logs -f
```

## Configuration

### Caddyfile Template Variables
The `Caddyfile.template` uses placeholder variables that you need to replace:

```caddy
# Replace {{DOMAIN}} with your actual domain
{{DOMAIN}} {
    reverse_proxy niabhail-tech-site:3000
}

# Replace {{DOMAIN}}
n8n.{{DOMAIN}} {
    reverse_proxy n8n-app:5678
}
```

### Adding New Services
To add a new service to the reverse proxy:

1. Add a new block to your `Caddyfile`:
```caddy
api.{{DOMAIN}} {
    reverse_proxy your-service:8080
}
```

2. Ensure your service's docker-compose.yml uses the shared network:
```yaml
networks:
  niabhail-tech-network:
    external: true
```

3. Reload Caddy configuration:
```bash
docker exec shared-caddy caddy reload --config /etc/caddy/Caddyfile
```

## Managing Subdomains

### Adding a New Subdomain

When you need to add a new service with its own subdomain:

1. **Edit your `Caddyfile`**:
```bash
vim Caddyfile
```

2. **Add the new subdomain block** (copy from n8n example):
```caddy
api.niabhail.tech {
    reverse_proxy api-service:8080
    
    encode gzip
    
    header {
        # Security headers
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
        
        # Remove server info
        -Server
    }
    
    # Logging
    log {
        output file /var/log/caddy/api.niabhail.tech.log {
            roll_size 10MB
            roll_keep 5
            roll_keep_for 720h
        }
        format json
        flush_interval -1
    }
}
```

3. **Reload Caddy configuration**:
```bash
docker exec shared-caddy caddy reload --config /etc/caddy/Caddyfile
```

4. **Verify the reload**:
```bash
# Check Caddy logs for any errors
docker logs shared-caddy --tail 20

# Test the new subdomain
curl -I https://api.niabhail.tech
```

### Updating the Template (Optional)

If you want to preserve the new subdomain pattern for future deployments:

1. **Update `Caddyfile.template`** with your new subdomain as a commented example
2. **Keep your working `Caddyfile`** - the deploy script won't overwrite it

### Common Subdomain Patterns

```caddy
# API service
api.{{DOMAIN}} {
    reverse_proxy api-service:8080
}

# Admin interface
admin.{{DOMAIN}} {
    reverse_proxy admin-app:3000
}

# Database admin (restrict access)
db.{{DOMAIN}} {
    reverse_proxy phpmyadmin:80
    # Add IP restrictions for security
    @restricted not remote_ip 192.168.1.0/24
    respond @restricted "Access denied" 403
}
```

## Directory Structure

```
niabhail-tech-shared-infra/
├── docker-compose.yml      # Infrastructure services
├── Caddyfile.template      # Caddy configuration template
├── Caddyfile              # Your customized configuration (git-ignored)
├── deploy.sh              # Deployment script
├── logs/                  # Caddy access logs
└── README.md              # This file
```

## Deployment Order

1. **First**: Deploy shared infrastructure (this project)
2. **Then**: Deploy application services (portfolio site, n8n, etc.)

Application services will automatically connect to the `niabhail-tech-network` and be routed by Caddy.

## Monitoring

### Health Checks
- Caddy health: `http://localhost:8080/health`
- Container status: `docker ps`
- Network status: `docker network ls | grep niabhail-tech-network`

### Logs
```bash
# Caddy container logs
docker compose logs -f shared-caddy

# Access logs (JSON format)
tail -f logs/niabhail.tech.log
```

### Admin API (Development Only)
- **Disabled by default** for security
- To enable: Uncomment port 2019 in `docker-compose.yml`
- URL: `http://localhost:2019` (when enabled)

## Security

### Production Checklist
- [x] Admin API disabled by default
- [ ] Configure firewall to allow only ports 80 and 443
- [ ] Review security headers in Caddyfile
- [ ] Set up log rotation and monitoring
- [ ] Configure backup for Caddy data volumes

### SSL Certificates
Caddy automatically manages SSL certificates via Let's Encrypt:
- Certificates stored in `shared_caddy_data` volume
- Auto-renewal enabled
- HTTPS redirects configured

## Troubleshooting

### Common Issues

**Network not found**
```bash
docker network create niabhail-tech-network
```

**Port conflicts**
```bash
# Check what's using port 80/443
sudo lsof -i :80
sudo lsof -i :443
```

**Certificate issues**
```bash
# Clear certificate cache
docker volume rm shared_caddy_data
docker compose up -d
```

### Support
For issues specific to this infrastructure, check:
1. Container logs: `docker compose logs`
2. Network connectivity: `docker network inspect niabhail-tech-network`
3. Caddy configuration: `docker exec shared-caddy caddy validate --config /etc/caddy/Caddyfile`

## Dependencies

- Docker Engine 20.10+
- Docker Compose 2.0+
- Ports 80, 443 available
- Domain DNS pointing to server IP