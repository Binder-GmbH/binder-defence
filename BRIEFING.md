# Briefing: binder-defence trustedHostsPattern Fix & Config Migration

**Date**: 2026-01-15
**Status**: ✅ Lokal funktionsfähig, aber Migration zu typo3-config-handling empfohlen
**Priority**: MEDIUM - Funktioniert, aber nicht optimal

## Aktueller Stand

### Was wurde gefixt

Das trustedHostsPattern Problem wurde **temporär** gelöst:

**Geänderte Datei:** [source/config/system/additional.php](source/config/system/additional.php)
```php
<?php

/**
 * Additional configuration for TYPO3
 * This file is loaded after settings.php and can override settings
 */

// Set trusted hosts pattern to allow all hosts (local development)
$GLOBALS['TYPO3_CONF_VARS']['SYS']['trustedHostsPattern'] = '.*';
```

### Aktuelles Problem

Diese Lösung:
- ✅ Funktioniert lokal
- ✅ Funktioniert auf stage/live (läuft ohne Fehler)
- ❌ **SICHERHEITSRISIKO** auf stage/live: `.*` erlaubt ALLE Hosts, auch Angreifer-Domains
- ❌ Keine saubere Trennung zwischen Development/Production Config

## Empfohlene Lösung: typo3-config-handling Package

### Was ist das?

**Package:** https://github.com/helhum/typo3-config-handling

Ein TYPO3 Package, das moderne Configuration Management ermöglicht:
- Environment-spezifische Config Files (development.yaml, production.yaml, stage.yaml)
- YAML statt PHP für bessere Lesbarkeit
- Encryption Support für Secrets
- Saubere Trennung zwischen Environments

**binder-world nutzt es bereits erfolgreich!**

### Vorteile

1. **Saubere Environment-Trennung**
   - `config/development.yaml` → trustedHostsPattern: '.*'
   - `config/production.yaml` → trustedHostsPattern: '(.*\.)?binder-defence\.com|...'

2. **Keine Sicherheitsrisiken mehr**
   - Jedes Environment hat seine eigene Config
   - Production ist automatisch sicher

3. **Bessere Wartbarkeit**
   - YAML ist übersichtlicher als PHP Arrays
   - Environment-Variablen via `%env(VAR)%` Syntax

4. **Secrets Management**
   - Encryption Support für Credentials
   - Verschlüsselte Werte können ins Git

### Wie binder-world es macht

**Analysiere:** `/Users/dbraendle/dev/_binder/binder-world`

#### 1. Package installiert in composer.json
```json
"helhum/typo3-config-handling": "^1.5"
```

#### 2. additional.php lädt Configs automatisch
[source/config/system/additional.php](file:///Users/dbraendle/dev/_binder/binder-world/source/config/system/additional.php):
```php
<?php

use TYPO3\CMS\Core\Core\Environment;
use Helhum\ConfigLoader\ConfigurationReaderFactory;
use Helhum\ConfigLoader\CachedConfigurationLoader;
use Helhum\ConfigLoader\ConfigurationLoader;

(function () {
    $context  = Environment::getContext()->isProduction() ? 'production' : 'development';
    $rootDir  = dirname(dirname(__DIR__));
    $confDir  = $rootDir . '/config';
    $cacheDir = $rootDir . '/var/cache/code/core';
    $envFile  = $rootDir . '/.env';
    $cacheIdentifier     = md5($context . filemtime($envFile));
    $configReaderFactory = new ConfigurationReaderFactory($confDir);
    $configLoader        = new CachedConfigurationLoader(
        $cacheDir,
        $cacheIdentifier,
        function () use ($confDir, $context, $configReaderFactory) {
            return new ConfigurationLoader(
                [
                    $configReaderFactory->createReader($confDir . '/' . $context . '.php'),
                    $configReaderFactory->createReader('TYPO3', ['type' => 'env']),
                ]
            );
        }
    );
    $GLOBALS['TYPO3_CONF_VARS'] = array_replace_recursive(
        $GLOBALS['TYPO3_CONF_VARS'],
        $configLoader->load()
    );
})();
```

#### 3. development.php mit trustedHostsPattern
[source/config/development.php](file:///Users/dbraendle/dev/_binder/binder-world/source/config/development.php#L9):
```php
<?php

return [
    'SYS'  => [
        'trustedHostsPattern' => '.*',  // Allows all hosts in development
        'displayErrors' => 1,
        'devIPmask'     => '*',
        // ... mehr Development-spezifische Settings
    ],
    'BE' => [
        'debug' => true,
        'sessionTimeout' => 60 * 60 * 24,
    ],
    'FE' => [
        'debug' => true,
    ],
];
```

#### 4. production.php mit restriktivem Pattern
Sie haben vermutlich eine `source/config/production.php` mit:
```php
'SYS' => [
    'trustedHostsPattern' => '(.*\.)?binder-world\.com',
    // Production-spezifische Settings
]
```

## Migration Steps (TODO)

### 1. Package installieren
```bash
cd source
composer require helhum/typo3-config-handling
```

### 2. Config Files erstellen

**source/config/development.php:**
```php
<?php

return [
    'SYS'  => [
        'trustedHostsPattern' => '.*',
        'displayErrors' => 1,
        'devIPmask'     => '*',
    ],
    'BE' => [
        'debug' => true,
        'sessionTimeout' => 60 * 60 * 24,
    ],
    'FE' => [
        'debug' => true,
    ],
];
```

**source/config/production.php:**
```php
<?php

return [
    'SYS'  => [
        'trustedHostsPattern' => '(.*\.)?binder-defence\.com|(.*\.)?binder-defense\.com|(.*\.)?binder-defence\.de|(.*\.)?binder-defense\.de',
        'displayErrors' => 0,
        'devIPmask'     => '',
    ],
    'BE' => [
        'debug' => false,
    ],
    'FE' => [
        'debug' => false,
    ],
];
```

### 3. additional.php updaten

Kopiere die Loader-Logik von binder-world's [additional.php](file:///Users/dbraendle/dev/_binder/binder-world/source/config/system/additional.php).

### 4. TYPO3_CONTEXT setzen

**.env (local):**
```bash
TYPO3_CONTEXT=Development/Local
```

**stage/live Server:**
```bash
TYPO3_CONTEXT=Production
```

### 5. Testen

```bash
# Lokal
docker compose down && docker compose up -d
curl -k -I https://binder-defence.local/typo3/

# Stage
# Deploy und testen

# Live
# Deploy und testen
```

## Aktuelle temporäre Lösung (Commit-Ready)

Die aktuelle Lösung kann committed werden, um lokal zu arbeiten:

```bash
git add source/config/system/additional.php
git commit -m "Fix trustedHostsPattern for local development (TEMPORARY)

SECURITY WARNING: This sets trustedHostsPattern to .* globally,
which is a security risk on production servers.

TODO: Migrate to helhum/typo3-config-handling for proper
environment-specific configuration management.

See BRIEFING.md for migration instructions.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**⚠️ WICHTIG:** Nach diesem Commit sollte die Migration zu typo3-config-handling Priorität haben, BEVOR auf stage/live deployed wird.

## Referenzen

- **Package:** https://github.com/helhum/typo3-config-handling
- **binder-world Projekt:** `/Users/dbraendle/dev/_binder/binder-world`
- **Speziell anschauen:**
  - `/Users/dbraendle/dev/_binder/binder-world/source/config/system/additional.php`
  - `/Users/dbraendle/dev/_binder/binder-world/source/config/development.php`
  - `/Users/dbraendle/dev/_binder/binder-world/source/composer.json` (für Package-Konfiguration)

## Zusammenfassung

**Jetzt:** Funktioniert lokal, aber `.*` auf allen Environments = Sicherheitsrisiko

**Nach Migration:** Jedes Environment hat seine eigene Config, Production ist automatisch sicher

**Nächster Schritt:** Migration zu `helhum/typo3-config-handling` nach binder-world Vorbild
