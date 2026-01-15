<?php

use TYPO3\CMS\Core\Cache\Backend\NullBackend;
use TYPO3\CMS\Core\Log\LogLevel;
use TYPO3\CMS\Core\Log\Writer\FileWriter;

return [
    'SYS'  => [
        'displayErrors'         => 1,
        'devIPmask'             => '*',
        'sqlDebug'              => 1,
        'trustedHostsPattern'   => '.*',
        'caching'       => [
            'cacheConfigurations' => [
                'pages' => [
                    'backend' => NullBackend::class,
                    'options' => [
                        'compression' => false,
                    ],
                ],
                'pagesection' => [
                    'backend' => NullBackend::class,
                    'options' => [
                        'compression' => false,
                    ],
                ],
                'assets' => [
                    'backend' => NullBackend::class,
                ],
                'fluid_template' => [
                    'backend' => NullBackend::class,
                ],
                'extbase' => [
                    'backend' => NullBackend::class,
                ],
                'di' => [
                    'backend' => NullBackend::class,
                ],
                'core' => [
                    'backend' => NullBackend::class,
                ],
            ],
        ],
    ],
    'BE' => [
        'debug'                   => true,
        'sessionTimeout'          => 60 * 60 * 24,
        'versionNumberInFilename' => false,
    ],
    'FE' => [
        'debug'                   => true,
        'versionNumberInFilename' => false,
        'compressionLevel'        => 0,
    ],
    'LOG'  => [
        'TYPO3' => [
            'CMS' => [
                'deprecations' => [
                    'writerConfiguration' => [
                        'notice' => [
                            'TYPO3\CMS\Core\Log\Writer\FileWriter' => [
                                'disabled' => false,
                            ],
                        ],
                    ],
                ],
            ]
        ],
        'writerConfiguration' => [
            LogLevel::DEBUG => [
                FileWriter::class => [],
            ],
        ],
    ],
];
