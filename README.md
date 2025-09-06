# Niabhail Tech Shared Infrastructure

Shared infrastructure for the niabhail.tech ecosystem. Provides foundational services including Caddy reverse proxy and shared Docker network.

## Features

- **Automatic HTTPS** with Let's Encrypt certificates
- **Reverse proxy** routing for multiple services
- **Shared Docker network** for service communication
- **Security headers** and compression
- **Request logging** and health monitoring

## Deployment

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+
- Ports 80, 443 available
- Domain DNS pointing to server IP

### Quick Deploy

1. **Clone repository**:
   ```bash
   git clone https://github.com/niabhail/niabhail-tech-shared-infra.git
   cd niabhail-tech-shared-infra
   ```

2. **Deploy**:
   ```bash
   chmod +x deploy.sh
   # Option 1: Auto-configure with domain parameter
   ./deploy.sh your-domain.com
   
   # Option 2: Manual configuration
   cp Caddyfile.template Caddyfile  # Edit and replace {{DOMAIN}}
   ./deploy.sh
   ```

3. **Verify**:
   ```bash
   docker ps  # Should show shared-caddy container running
   docker network ls | grep niabhail-tech-network  # Should show the shared network
   ```

## Configuration

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


## Monitoring

### Health Checks
- Container status: `docker ps`
- Network status: `docker network ls | grep niabhail-tech-network`

### Logs
```bash
# Caddy container logs
docker compose logs -f shared-caddy

# Access logs (JSON format)
tail -f logs/*.log
```


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

### Debug Commands
```bash
# Container logs
docker compose logs

# Network connectivity  
docker network inspect niabhail-tech-network

# Validate Caddy config
docker exec shared-caddy caddy validate --config /etc/caddy/Caddyfile
```

## Related Projects

- **[niabhail-tech-site](https://github.com/niabhail/niabhail-tech-site)** - Portfolio website
- **[niabhail-tech-n8n](https://github.com/niabhail/niabhail-tech-n8n)** - Automation platform