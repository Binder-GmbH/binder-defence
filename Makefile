.DEFAULT_GOAL := help
.PHONY: help start stop restart shell composer-install composer-require composer-update extension-setup rebuild cache-clear

# Show available commands
help:
	@echo "╔══════════════════════════════════════════════════════════════╗"
	@echo "║              TYPO3 Docker Development Commands               ║"
	@echo "╚══════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Container Management:"
	@echo "  make start              - Start all containers"
	@echo "  make stop               - Stop all containers"
	@echo "  make restart            - Restart all containers"
	@echo "  make shell              - Open shell in app container"
	@echo "  make rebuild            - Rebuild app container (after Dockerfile changes)"
	@echo ""
	@echo "Composer/Extension Management:"
	@echo "  make composer-install   - Install all dependencies from composer.lock"
	@echo "  make composer-update    - Update all dependencies"
	@echo "  make composer-require EXT=vendor/package"
	@echo "                          - Install new package (e.g., EXT=georgringer/news)"
	@echo "  make extension-setup    - Setup TYPO3 extension database tables"
	@echo ""
	@echo "TYPO3 Commands:"
	@echo "  make cache-clear        - Clear all TYPO3 caches"
	@echo ""

# Start all containers
start:
	docker compose up -d
	@echo "✅ All containers started"
	@echo "🌐 Frontend: https://binder-defence.local"
	@echo "🔧 Backend: https://binder-defence.local/typo3"

# Stop all containers
stop:
	docker compose stop
	@echo "✅ All containers stopped"

# Restart all containers
restart: stop start

# Open shell in app container
shell:
	docker exec -it binder-defence-app-1 bash

# Install composer dependencies
composer-install:
	@echo "📦 Installing composer dependencies..."
	docker exec -w /app/source binder-defence-app-1 composer install --no-dev --optimize-autoloader
	@echo "🔧 Fixing permissions..."
	docker exec binder-defence-app-1 chown -R application:application /app/source/var/
	@echo "✅ Dependencies installed"

# Update composer dependencies
composer-update:
	@echo "📦 Updating composer dependencies..."
	docker exec -w /app/source binder-defence-app-1 composer update --no-dev --optimize-autoloader
	@echo "🔧 Fixing permissions..."
	docker exec binder-defence-app-1 chown -R application:application /app/source/var/
	@echo "✅ Dependencies updated"

# Install new composer package
composer-require:
	@if [ -z "$(EXT)" ]; then \
		echo "❌ Error: Please specify an extension"; \
		echo "Usage: make composer-require EXT=vendor/package"; \
		echo "Example: make composer-require EXT=georgringer/news"; \
		exit 1; \
	fi
	@echo "📦 Installing $(EXT)..."
	@echo "🔧 Fixing composer.json permissions for write access..."
	docker exec binder-defence-app-1 chmod 666 /app/source/composer.json
	docker exec -w /app/source binder-defence-app-1 composer require $(EXT)
	@echo "🔧 Restoring composer.json permissions..."
	docker exec binder-defence-app-1 chmod 644 /app/source/composer.json
	@echo "🔧 Setting up database tables..."
	docker exec binder-defence-app-1 php vendor/bin/typo3 extension:setup
	@echo "🔧 Fixing permissions..."
	docker exec binder-defence-app-1 chown -R application:application /app/source/var/
	@echo "✅ Extension $(EXT) installed and configured"

# Setup TYPO3 extension database tables
extension-setup:
	@echo "🔧 Setting up extension database tables..."
	docker exec binder-defence-app-1 php vendor/bin/typo3 extension:setup
	@echo "✅ Database tables created/updated"

# Rebuild app container (needed when Dockerfile changes or BASE_IMAGE updates)
rebuild:
	@echo "🔨 Rebuilding app container..."
	DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build app
	docker compose up -d app
	@echo "✅ Container rebuilt and started"

# Clear TYPO3 caches
cache-clear:
	@echo "🧹 Clearing TYPO3 caches..."
	docker exec binder-defence-app-1 php vendor/bin/typo3 cache:flush
	@echo "✅ All caches cleared"