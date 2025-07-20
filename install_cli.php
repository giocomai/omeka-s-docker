#!/usr/bin/env php
<?php
/**
 * Omeka S CLI installer
 *
 * This script performs the initial Omeka S installation using command-line arguments.
 * It is typically invoked automatically at container startup if environment variables
 * like OMEKA_ADMIN_EMAIL, OMEKA_ADMIN_NAME, etc. are provided.
 *
 * The script is idempotent: if Omeka S is already installed (based on DB tables),
 * it will exit safely without attempting to reinstall.
 *
 * Usage (example):
 *   php install_cli.php --email=admin@example.com --name="Admin" --password=secret --title="My Site"
 *
 * Optional:
 *   --timezone=Atlantic/Canary   (default: UTC)
 *   --locale=es                  (default: en_US)
 */

if (PHP_SAPI !== 'cli') {
    echo "CLI only\n";
    exit(1);
}

$options = getopt('', [
    'email:',
    'name:',
    'password:',
    'title:',
    'timezone::',
    'locale::',
]);
if (empty($options['email']) || empty($options['name'])
    || empty($options['password']) || empty($options['title'])
) {
    echo "Usage:\n";
    echo "  php install_cli.php --email=EMAIL --name=NAME --password=PASS "
       . "--title=TITLE [--timezone=UTC] [--locale=en_US]\n";
    exit(1);
}

require 'bootstrap.php';
$app = \Laminas\Mvc\Application::init(
    require 'application/config/application.config.php'
);
$services = $app->getServiceManager();

// Get the raw DB connection from Omeka
/** @var \Laminas\Db\Adapter\AdapterInterface $connection */
$connection = $services->get('Omeka\Connection');

// Check if the 'api_key' table already exists; if so, assume installed
$found = $connection->fetchOne('SHOW TABLES LIKE ?', ['api_key']);
if ($found) {
    echo "Omeka S is already installed.\n";
    exit(0);
}

$status = $services->get('Omeka\\Status');
if ($status->isInstalled()) {
    echo "Omeka S is already installed.\n";
    exit(0);
}

$installer = $services->get('Omeka\\Installer');

$installer->registerVars(
    Omeka\Installation\Task\CreateFirstUserTask::class,
    [
        'email' => $options['email'],
        'name'  => $options['name'],
        'password-confirm' => [
            'password'         => $options['password'],
            'password-confirm' => $options['password'],
        ],
    ]
);
$installer->registerVars(
    Omeka\Installation\Task\AddDefaultSettingsTask::class,
    [
        'administrator_email' => $options['email'],
        'installation_title'  => $options['title'],
        'time_zone'           => $options['timezone'] ?? 'UTC',
        'locale'              => $options['locale'] ?? 'en_US',
    ]
);

if ($installer->install()) {
    echo "Installation completed.\n";

} else {
    echo "Installation failed:\n";
    foreach ($installer->getErrors() as $err) {
        echo " - $err\n";
    }
    exit(1);
}
