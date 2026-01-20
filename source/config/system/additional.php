<?php

use TYPO3\CMS\Core\Core\Environment;
use Helhum\ConfigLoader\ConfigurationReaderFactory;
use Helhum\ConfigLoader\CachedConfigurationLoader;
use Helhum\ConfigLoader\ConfigurationLoader;
use TYPO3\CMS\Core\Log\LogLevel;
use TYPO3\CMS\Core\Log\Writer\FileWriter;

(function () {
    $context  = Environment::getContext()->isProduction() ? 'production' : 'development';
    $rootDir  = dirname(dirname(__DIR__));
    $confDir  = $rootDir . '/config';
    $cacheDir = $rootDir . '/var/cache/code/core';
    $envFile  = $rootDir . '/.env';
    $cacheIdentifier     = md5($context . (file_exists($envFile) ? filemtime($envFile) : ''));
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

/*
 |--------------------------------------------------------------------------
 | Performance setup for production
 |--------------------------------------------------------------------------
 */
if (Environment::getContext()->isProduction()) {
    $GLOBALS['TYPO3_CONF_VARS']['SYS']['errorHandler'] = '';
    $GLOBALS['TYPO3_CONF_VARS']['SYS']['errorHandlerErrors'] = '5890';
    $GLOBALS['TYPO3_CONF_VARS']['SYS']['debugExceptionHandler'] = '';
    $GLOBALS['TYPO3_CONF_VARS']['SYS']['belogErrorReporting'] = '0';
    $GLOBALS['TYPO3_CONF_VARS']['LOG']['TYPO3']['CMS']['deprecations']['writerConfiguration'][LogLevel::NOTICE] = [];

    $GLOBALS['TYPO3_CONF_VARS']['LOG']['writerConfiguration'][LogLevel::DEBUG] = [];
    $GLOBALS['TYPO3_CONF_VARS']['LOG']['writerConfiguration'][LogLevel::WARNING] = [];

    $GLOBALS['TYPO3_CONF_VARS']['LOG']['writerConfiguration'][LogLevel::ERROR] = [
        FileWriter::class => [],
    ];
}
/*
 |-------------------------------------------------------------------------------------------------
 | Filefill configuration. Must not be turned on in production environment.
 |-------------------------------------------------------------------------------------------------
 */
if (in_array(
    Environment::getContext()->__toString(),
    ['Development/Stage', 'Production/develop', 'Production/Dev', 'Development/Local']
)) {
    $GLOBALS['TYPO3_CONF_VARS']['BE']['versionNumberInFilename'] = false;
    $GLOBALS['TYPO3_CONF_VARS']['FE']['versionNumberInFilename'] = false;
    $GLOBALS['TYPO3_CONF_VARS']['EXTCONF']['filefill']['storages'][1] = [
        [
            'identifier' => 'domain',
            'configuration' => 'https://binder-defence.local',
        ],
    ];
}