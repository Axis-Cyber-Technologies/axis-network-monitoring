#!/usr/local/bin/php
<?php

require_once 'script/load_phalcon.php';
require_once '/usr/local/opnsense/mvc/app/library/OPNsense/AxisNetworkMonitor/Logger.php';

use OPNsense\AxisNetworkMonitor\AxisNetworkMonitor;
use OPNsense\AxisNetworkMonitor\Logger;
use OPNsense\Core\Backend;
use OPNsense\Core\Config;

if ($argc < 2) {
    echo "Usage: toggle_enable.php <enable|disable>\n";
    exit(1);
}

$action = $argv[1];
if (!in_array($action, ['enable', 'disable'], true)) {
    echo "Invalid action. Use enable or disable.\n";
    exit(1);
}

$model = new AxisNetworkMonitor();
$backend = new Backend();

$enable = $action === 'enable';
$model->general->enabled = $enable ? '1' : '0';
$model->general->onboot = $enable ? '1' : '0';
$model->serializeToConfig();
Config::getInstance()->save();

// Enable/disable services at boot
if ($enable) {
    foreach (['redis', 'fluent-bit'] as $dep) {
        $backend->configdRun(sprintf('axisnetworkmonitor dependency-manage install %s', $dep));
        $backend->configdRun(sprintf('axisnetworkmonitor dependency-manage enable %s', $dep));
        $backend->configdRun(sprintf('axisnetworkmonitor dependency-manage start %s', $dep));
    }
} else {
    foreach (['redis', 'fluent-bit'] as $dep) {
        $backend->configdRun(sprintf('axisnetworkmonitor dependency-manage stop %s', $dep));
        $backend->configdRun(sprintf('axisnetworkmonitor dependency-manage disable %s', $dep));
    }
}

Logger::log('notice', 'Plugin ' . $action, [
    'enabled' => $enable,
]);

echo "Axis Network Monitor has been {$action}d.\n";
