<?php

use TYPO3\CMS\Core\Core\Environment;
use Helhum\ConfigLoader\ConfigurationReaderFactory;
use Helhum\ConfigLoader\CachedConfigurationLoader;
use Helhum\ConfigLoader\ConfigurationLoader;

/**
 * Additional configuration for TYPO3
 * This file loads environment-specific configuration from config/development.php or config/production.php
 * based on the TYPO3_CONTEXT environment variable.
 */

(function () {
    $context  = Environment::getContext()->isProduction() ? 'production' : 'development';
    $rootDir  = dirname(dirname(__DIR__));
    $confDir  = $rootDir . '/config';
    $cacheDir = $rootDir . '/var/cache/code/core';
    $envFile  = $rootDir . '/.env';

    // Only use cache identifier if .env exists
    $cacheIdentifier = file_exists($envFile)
        ? md5($context . filemtime($envFile))
        : md5($context);

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
