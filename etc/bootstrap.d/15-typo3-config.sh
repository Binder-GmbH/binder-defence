#!/usr/bin/env bash

# Update TYPO3 configuration with environment variables
if [ -n "$TYPO3_ENCRYPTION_KEY" ]; then
    echo "Configuring TYPO3 settings from environment..."

    su -p application <<EOFPHP
    php -r "
    \\\$settingsFile = '/app/source/config/system/settings.php';
    \\\$settings = require \\\$settingsFile;
    \\\$changed = false;

    // Set encryption key if empty
    if (empty(\\\$settings['SYS']['encryptionKey'])) {
        \\\$settings['SYS']['encryptionKey'] = getenv('TYPO3_ENCRYPTION_KEY');
        \\\$changed = true;
        echo 'Encryption key set' . PHP_EOL;
    }

    // Configure trusted hosts pattern for all binder-defence/defense domains
    \\\$trustedPattern = '.*\\\\.binder-defence\\\\.com|.*\\\\.binder-defense\\\\.com|.*\\\\.binder-defence\\\\.de|.*\\\\.binder-defense\\\\.de';
    if (!isset(\\\$settings['SYS']['trustedHostsPattern']) || \\\$settings['SYS']['trustedHostsPattern'] !== \\\$trustedPattern) {
        \\\$settings['SYS']['trustedHostsPattern'] = \\\$trustedPattern;
        \\\$changed = true;
        echo 'Trusted hosts pattern set' . PHP_EOL;
    }

    // Configure reverse proxy settings for Traefik
    if (!isset(\\\$settings['BE']['lockSSL']) || \\\$settings['BE']['lockSSL'] !== true) {
        \\\$settings['BE']['lockSSL'] = true;
        \\\$changed = true;
    }
    if (!isset(\\\$settings['SYS']['reverseProxySSL']) || \\\$settings['SYS']['reverseProxySSL'] !== '*') {
        \\\$settings['SYS']['reverseProxySSL'] = '*';
        \\\$changed = true;
    }
    if (!isset(\\\$settings['SYS']['reverseProxyIP']) || \\\$settings['SYS']['reverseProxyIP'] !== '*') {
        \\\$settings['SYS']['reverseProxyIP'] = '*';
        \\\$changed = true;
    }

    // Write settings if changed
    if (\\\$changed) {
        file_put_contents(\\\$settingsFile, '<?php' . PHP_EOL . 'return ' . var_export(\\\$settings, true) . ';' . PHP_EOL);
        echo 'TYPO3 settings configured successfully' . PHP_EOL;
    } else {
        echo 'TYPO3 settings already configured' . PHP_EOL;
    }
    "
EOFPHP
else
    echo "TYPO3_ENCRYPTION_KEY not set in environment"
fi
