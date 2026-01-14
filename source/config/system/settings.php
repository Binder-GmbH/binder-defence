<?php
return [
    'DB' => [
        'Connections' => [
            'Default' => [
                'charset' => 'utf8mb4',
                'dbname' => getenv('MYSQL_DATABASE') ?: 'typo3',
                'driver' => 'mysqli',
                'host' => getenv('MYSQL_HOST') ?: 'mysql',
                'password' => getenv('MYSQL_PASSWORD') ?: '',
                'port' => (int)(getenv('MYSQL_PORT') ?: 3306),
                'user' => getenv('MYSQL_USER') ?: 'typo3',
            ],
        ],
    ],
    'EXTENSIONS' => [
        'backend' => [
            'loginBackgroundImage' => '',
            'loginHighlightColor' => '',
            'loginLogo' => '',
            'loginLogoAlt' => '',
        ],
    ],
];
