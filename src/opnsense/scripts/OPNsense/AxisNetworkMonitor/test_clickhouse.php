#!/usr/local/bin/php
<?php
require_once 'script/load_phalcon.php';
require_once '/usr/local/opnsense/mvc/app/library/OPNsense/AxisNetworkMonitor/Logger.php';

use OPNsense\AxisNetworkMonitor\Logger;

$options = getopt('', ['host:', 'port:', 'user::', 'password::', 'tls::']);
$host = $options['host'] ?? '127.0.0.1';
$port = isset($options['port']) ? (int)$options['port'] : 8123;
$user = $options['user'] ?? '';
$password = $options['password'] ?? '';
$tls = isset($options['tls']) ? filter_var($options['tls'], FILTER_VALIDATE_BOOLEAN) : false;

$scheme = $tls ? 'https' : 'http';
$url = sprintf('%s://%s:%d/ping', $scheme, $host, $port);

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);

if ($user !== '') {
    curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    curl_setopt($ch, CURLOPT_USERPWD, $user . ':' . $password);
}

$result = curl_exec($ch);
$error = curl_error($ch);
$code = curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
curl_close($ch);

$success = ($error === '' && ($code === 200 || $result === 'Ok'));

Logger::log($success ? 'info' : 'error', 'ClickHouse connectivity test', [
    'host' => $host,
    'port' => $port,
    'tls' => $tls,
    'success' => $success,
    'http_code' => $code,
    'error' => $error,
]);

$output = [
    'success' => $success,
    'http_code' => $code,
    'response' => $result,
    'error' => $error,
];

echo json_encode($output);
