#!/usr/local/bin/php
<?php
require_once 'script/load_phalcon.php';
require_once '/usr/local/opnsense/mvc/app/library/OPNsense/AxisNetworkMonitor/Logger.php';

use OPNsense\AxisNetworkMonitor\Logger;

$options = getopt('', ['host:', 'port:', 'password::']);
$host = $options['host'] ?? '127.0.0.1';
$port = isset($options['port']) ? (int)$options['port'] : 6379;
$password = $options['password'] ?? '';

$args = [
    '/usr/local/bin/redis-cli',
    '-h', escapeshellarg($host),
    '-p', (string)$port,
    'PING'
];
$command = '/usr/local/bin/redis-cli -h ' . escapeshellarg($host) . ' -p ' . escapeshellarg((string)$port);
if ($password !== '') {
    $command .= ' -a ' . escapeshellarg($password);
}
$command .= ' PING';

exec($command . ' 2>&1', $output, $code);
$response = trim(implode("\n", $output));
$success = ($code === 0 && strtoupper($response) === 'PONG');

Logger::log($success ? 'info' : 'error', 'Redis connectivity test', [
    'host' => $host,
    'port' => $port,
    'success' => $success,
    'response' => $response,
]);

echo json_encode([
    'success' => $success,
    'response' => $response,
]);
