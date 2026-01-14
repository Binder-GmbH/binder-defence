# Deployment Strategy for binder-defence

## WICHTIG: Docker Image Deployment (wie binder-world)

**NICHT** rsync-basiertes Deployment verwenden!

## Korrekte Deployment-Strategie (binder-world Modell)

### 1. CI/CD Pipeline Flow

```
Push → Compile → Build Docker Image → Push Image → Deploy Container
```

### 2. Build Process

1. **Compile Stage** (GitHub Actions)
   - PHP 8.4
   - `composer install --no-dev --optimize-autoloader --ignore-platform-reqs`
   - Frontend Build (wenn nötig)

2. **Build Stage** (GitHub Actions)
   - Docker Image bauen mit fertigem Code
   - Image enthält: vendor/, public/, config/, alles kompiliert
   - Image pushen zu GitHub Container Registry

3. **Deploy Stage** (GitHub Actions)
   - SSH zum Server
   - `docker compose pull app`
   - `docker compose up -d app`

### 3. Bootstrap Scripts (Container Start)

Im Container beim Start ausführen (`etc/bootstrap.d/`):

1. **01-export-env.sh** - Env vars exportieren
2. **10-required-folders.sh** - Ordner erstellen
3. **20-db-migrate.sh** - Database Schema Update
   ```bash
   /tmp/wait-for-it.sh mysql:3306 -t 360
   typo3 database:updateschema "*.add,*.change"
   typo3 cache:flush
   typo3 cache:warmup
   ```

### 4. Was NICHT deployed wird

- `var/` - Wird auf dem Server persistiert
- `public/fileadmin/` - User uploads
- `public/typo3temp/` - Cache
- `config/system/settings.php` - Server-spezifisch (einmal Setup, dann bleibt)

### 5. Was deployed wird

- **Komplettes Docker Image** mit:
  - source/ mit vendor/
  - public/ mit kompilierten Assets
  - config/system/additional.php (trustedHostsPattern)
  - etc/bootstrap.d/ Scripts

### 6. Server Setup (einmalig)

1. Docker & Docker Compose installiert
2. docker-compose.yml auf Server
3. Volumes gemountet für: var/, fileadmin/, typo3temp/
4. TYPO3 Setup einmal ausführen (manuell oder Init-Container)
5. Danach: Nur noch Image-Updates via `docker compose pull && up -d`

## Warum KEIN rsync?

❌ rsync deployed nur Files, nicht kompilierte Images
❌ Permissions-Probleme
❌ Kein Rollback möglich
❌ Inkonsistente States möglich

✅ Docker Image = Atomic Deployment
✅ Rollback = vorheriges Image
✅ Konsistenter State garantiert

## Status

- ❌ Aktuell: rsync-basiert (FALSCH)
- ✅ Soll: Docker Image-basiert (wie binder-world)
- 🚧 TODO: Umstellung auf Image-Deployment
