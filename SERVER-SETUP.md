# Server Setup für binder-defence

## Deployment-Architektur

**Image-basiertes Deployment** wie binder-world:
1. GitHub Actions kompiliert TYPO3 (composer install)
2. Docker Image wird gebaut mit allen kompilierten Files
3. Image wird zu GitHub Container Registry (ghcr.io) gepusht
4. Server pullt das fertige Image und startet Container

## Server-Struktur

```
/var/www/binder-defence/
├── docker-compose.yml          # Wird von GitHub deployed
├── .env.stage                  # Stage environment vars (manuell erstellen)
├── .env.live                   # Live environment vars (manuell erstellen)
├── stage/                      # Stage persistent volumes
│   ├── var/                    # TYPO3 logs, cache
│   ├── fileadmin/              # User uploads
│   ├── typo3temp/              # Temp files
│   └── shared/                 # Other persistent data
└── live/                       # Live persistent volumes
    ├── var/
    ├── fileadmin/
    ├── typo3temp/
    └── shared/
```

## Erstmaliges Server-Setup

### 1. Voraussetzungen

- Docker & Docker Compose installiert
- Traefik als Reverse Proxy läuft (mit `web` network)
- SSH-Zugriff für GitHub Actions

### 2. Server-Ordner erstellen

```bash
ssh BINDER_DigitalOcean

# Hauptordner erstellen
mkdir -p /var/www/binder-defence

# Persistent Volumes für Stage
mkdir -p /var/www/binder-defence/stage/{var,fileadmin,typo3temp,shared}

# Persistent Volumes für Live
mkdir -p /var/www/binder-defence/live/{var,fileadmin,typo3temp,shared}

# Permissions setzen (UID 1000 = application user im Container)
chown -R 1000:1000 /var/www/binder-defence/stage
chown -R 1000:1000 /var/www/binder-defence/live
```

### 3. Environment Files erstellen

**Stage: `/var/www/binder-defence/.env.stage`**
```bash
# Docker Compose
GITHUB_REPOSITORY=USER/binder-defence
APP_DOMAIN=stage.binder-defence.com

# MySQL
MYSQL_HOST=mysql
MYSQL_ROOT_PASSWORD=SECURE_PASSWORD_HERE
MYSQL_USER=typo3_stage
MYSQL_PASSWORD=SECURE_PASSWORD_HERE
MYSQL_DATABASE=typo3_stage
MYSQL_PORT=3306

# Application
APPLICATION_UID=1000
APPLICATION_GID=1000
```

**Live: `/var/www/binder-defence/.env.live`**
```bash
# Docker Compose
GITHUB_REPOSITORY=USER/binder-defence
APP_DOMAIN=binder-defence.com

# MySQL
MYSQL_HOST=mysql
MYSQL_ROOT_PASSWORD=SECURE_PASSWORD_HERE
MYSQL_USER=typo3_live
MYSQL_PASSWORD=SECURE_PASSWORD_HERE
MYSQL_DATABASE=typo3_live
MYSQL_PORT=3306

# Application
APPLICATION_UID=1000
APPLICATION_GID=1000
```

### 4. Traefik Network (falls noch nicht vorhanden)

```bash
docker network create web
```

### 5. GitHub Secrets konfigurieren

Im GitHub Repository unter Settings → Secrets → Actions:

**SSH Access:**
- `SSH_PRIVATE_KEY`: SSH Private Key für Server-Zugriff
- `SSH_USER`: SSH User (z.B. `root` oder `deployer`)
- `STAGE_HOST`: Stage Server IP/Domain
- `LIVE_HOST`: Live Server IP/Domain

Die Workflows nutzen automatisch `GITHUB_TOKEN` für ghcr.io Login.

### 6. Erstes Deployment triggern

```bash
# Lokal:
git push origin develop    # Deployed nach Stage
git push origin main        # Deployed nach Live
```

## Was passiert beim Deployment?

### GitHub Actions Pipeline:

1. **Compile Job:**
   - PHP 8.4 Setup
   - `composer install --no-dev --optimize-autoloader --ignore-platform-reqs`
   - Source als Artifact hochladen

2. **Build Job:**
   - Dockerfile bauen mit kompiliertem Code
   - Image zu `ghcr.io/USER/binder-defence:stage` pushen

3. **Deploy Job:**
   - `docker-compose.stage.yml` zum Server kopieren
   - Server: `docker compose pull app`
   - Server: `docker compose up -d app`

### Container Start (Bootstrap Scripts):

1. **01-export-env.sh**: Environment vars exportieren
2. **10-required-folders.sh**: Ordner erstellen, Permissions fixen
3. **20-db-migrate.sh**:
   - Warten auf MySQL
   - `typo3 database:updateschema "*.add,*.change"`
   - `typo3 cache:flush && cache:warmup`

## TYPO3 Initial Setup (nur beim ersten Mal)

### Option A: Manuell via CLI

```bash
ssh BINDER_DigitalOcean
cd /var/www/binder-defence

# In Container gehen
docker compose exec app bash

# TYPO3 Setup
php typo3 setup

# Admin User erstellen
php typo3 backend:createadmin
```

### Option B: Via Web-Installer

1. Browser: `https://stage.binder-defence.com/typo3/install.php`
2. Setup Wizard durchlaufen
3. Datenbank-Credentials aus `.env.stage` verwenden

## Was liegt wo?

### Im Docker Image (kompiliert, read-only):
- `source/vendor/` - Composer Dependencies
- `source/public/` - Frontend Assets
- `source/config/` - TYPO3 Config
- Templates, Extensions, PHP Code

### Am Server (persistent, read-write):
- `stage/var/` - Logs, Cache
- `stage/fileadmin/` - User Uploads
- `stage/typo3temp/` - TYPO3 Temp Files
- `stage/shared/` - Sonstige persistente Daten

## Debugging

### Logs anschauen
```bash
cd /var/www/binder-defence
docker compose logs -f app
docker compose logs -f mysql
```

### In Container gehen
```bash
docker compose exec app bash
ls -la /app/source/
php typo3 cache:flush
```

### Image-Info
```bash
docker images | grep binder-defence
docker inspect ghcr.io/USER/binder-defence:stage
```

### Rollback auf vorheriges Image
```bash
# Zeige alle verfügbaren Images
docker images | grep binder-defence

# Zurück zu älterem Image
docker tag ghcr.io/USER/binder-defence:stage-abc123 ghcr.io/USER/binder-defence:stage
docker compose up -d app
```

## Unterschied zu bisherigem rsync-Deployment

| Alt (rsync) | Neu (Image-based) |
|-------------|-------------------|
| ❌ Files werden kopiert | ✅ Komplettes Image wird deployed |
| ❌ Kein Rollback möglich | ✅ Rollback via Image-Tags |
| ❌ Inkonsistente States möglich | ✅ Atomic Deployment |
| ❌ Server muss kompilieren | ✅ GitHub baut alles |
| ❌ Permission-Probleme | ✅ Image hat korrekte Permissions |

## Wichtige Hinweise

- **Images sind NICHT sichtbar am Server**: Files liegen im Container, nicht im Filesystem
- **Persistent Volumes** bleiben bei Updates erhalten
- **Database** läuft separat als eigener Container
- **Traefik** routet Traffic zu den Containern
- **.env Files** sind server-spezifisch, werden NICHT committed
