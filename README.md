# BINDER Defence - TYPO3 13.4 Project

TYPO3 CMS project for BINDER Defence with Docker Compose setup and CI/CD pipeline.

## Tech Stack

- **TYPO3**: v13.4 (Composer-based)
- **PHP**: 8.4 (webdevops/php-nginx)
- **MySQL**: 8.0
- **Redis**: 8.0-alpine
- **Traefik**: 2.11.0 (Reverse proxy with SSL)
- **phpMyAdmin**: Database management
- **Mailhog**: Email testing

## Environments

- **Local**: https://binder-defence.local
- **Stage**: https://stage.binder-defence.com
- **Live**: https://www.binder-defence.com

## Prerequisites

- Docker Desktop installed
- Git installed
- Terminal access (macOS: Terminal/iTerm2, Windows: PowerShell/WSL2)

## Local Setup

### 1. Clone Repository

```bash
git clone [repository-url]
cd binder-defence
```

### 2. Add Local Domains to /etc/hosts

**macOS/Linux:**
```bash
sudo sh -c 'echo "127.0.0.1 binder-defence.local pma.binder-defence.local mail.binder-defence.local" >> /etc/hosts'
```

**Windows (PowerShell as Administrator):**
```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 binder-defence.local pma.binder-defence.local mail.binder-defence.local"
```

### 3. Start Docker Containers

```bash
docker-compose up -d --build
```

Wait for all containers to start (this may take a few minutes on first run).

### 4. Install TYPO3 Dependencies

```bash
docker exec -u application binder-defence-app-1 composer install --no-dev --optimize-autoloader
```

### 5. Access the Application

- **Frontend**: https://binder-defence.local
- **Backend**: https://binder-defence.local/typo3
- **phpMyAdmin**: https://pma.binder-defence.local
- **Mailhog**: https://mail.binder-defence.local

**Note**: Your browser will show a security warning for the self-signed SSL certificate. This is expected for local development. Click "Advanced" → "Proceed to site" (Chrome) or "Accept the Risk" (Firefox).

## Database Credentials

### Local Environment

```
Host: mysql
Database: typo3
Username: typo3_local
Password: bN7qW3xRmK9pL2vGhJ
Port: 3306
Root Password: Kx9mPvL2nQ8wZr4TjY
```

**Note**: These are local development credentials only and are safe to commit. Production and staging credentials are managed via GitHub Secrets and never committed to the repository.

### TYPO3 Backend Login

Use the credentials you created during the installation wizard.

## Common Commands

### Start Containers
```bash
docker-compose up -d
```

### Stop Containers
```bash
docker-compose down
```

### Rebuild Containers
```bash
docker-compose up -d --build
```

### View Logs
```bash
docker-compose logs -f app
```

### Access App Container Shell
```bash
docker exec -it -u application binder-defence-app-1 bash
```

### Clear TYPO3 Cache
```bash
docker exec -u application binder-defence-app-1 find /app/source/var/cache -type f -delete
```

### Run Composer Commands
```bash
docker exec -u application binder-defence-app-1 composer [command]
```

## Project Structure

```
binder-defence/
├── docker/
│   ├── mysql/              # MySQL configuration
│   └── traefik/            # Traefik SSL certificates
├── etc/
│   └── php/                # PHP configuration
├── source/                 # TYPO3 source code (Composer-managed)
│   ├── composer.json
│   ├── config/
│   │   └── sites/          # Site configurations
│   ├── public/             # Document root
│   └── vendor/             # Composer dependencies
├── docker-compose.yml      # Docker services definition
├── Dockerfile              # PHP/NGINX container build
├── .env                    # Environment variables
└── .gitignore
```

## CI/CD Pipeline

### GitHub Actions Workflows

- **deploy-stage.yml**: Deploys `develop` branch to stage.binder-defence.com
- **deploy-live.yml**: Deploys `main` branch to www.binder-defence.com

### Deployment Process

1. **Stage Deployment**:
   - Push to `develop` branch
   - GitHub Actions builds and deploys to stage server
   - Accessible at https://stage.binder-defence.com

2. **Live Deployment**:
   - Merge `develop` → `main`
   - GitHub Actions builds and deploys to live server
   - Accessible at https://www.binder-defence.com

## Server Information

- **Server IP**: 164.92.184.1
- **Stage Path**: `/var/www/binder-defence-stage`
- **Live Path**: `/var/www/binder-defence-live`

## Troubleshooting

### Container Issues

**Problem**: Containers won't start
```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs
```

**Problem**: Port already in use
```bash
# Stop conflicting containers
docker ps
docker stop [container-name]
```

### TYPO3 Issues

**Problem**: 503 Backend Error
```bash
# Clear cache and restart
docker exec -u application binder-defence-app-1 find /app/source/var/cache -type f -delete
docker-compose restart app
```

**Problem**: Database connection failed
```bash
# Verify MySQL is running
docker-compose ps mysql

# Check MySQL logs
docker-compose logs mysql
```

### SSL Certificate Warnings

The local environment uses self-signed SSL certificates. Your browser will warn you about this. For local development, you can safely proceed past this warning.

## Team Setup

This setup works identically on:
- Mac 1 (M1/M2/M3 Apple Silicon)
- Mac 2 (Intel)
- Windows PC (with Docker Desktop + WSL2)

Each team member should:
1. Clone the repository
2. Follow the "Local Setup" steps above
3. Use the same `.env` file (committed to repository)

## Support

For issues or questions:
1. Check this README
2. Review Docker logs: `docker-compose logs`
3. Contact the development team

## License

Proprietary - BINDER GmbH
