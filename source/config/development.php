<?php

return [
    'SYS' => [
        'trustedHostsPattern' => '.*',
        'displayErrors' => 1,
        'devIPmask' => '*',
    ],
    'BE' => [
        'debug' => true,
        'sessionTimeout' => 60 * 60 * 24,
    ],
    'FE' => [
        'debug' => true,
    ],
];
