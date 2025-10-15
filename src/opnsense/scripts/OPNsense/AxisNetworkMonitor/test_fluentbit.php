#!/usr/local/bin/php
<?php
require_once 'script/load_phalcon.php';
require_once '/usr/local/opnsense/mvc/app/library/OPNsense/AxisNetworkMonitor/Logger.php';

use OPNsense\AxisNetworkMonitor\Logger;

$options = getopt('', ['host:', 'port:', 'tls::']);
$host = $options['host'] ?? '127.0.0.1';
$port = isset($options['port']) ? (int)$options['port'] : 2021;
$tls = isset($options['tls']) ? filter_var($options['tls'], FILTER_VALIDATE_BOOLEAN) : false;

$scheme = $tls ? 'https' : 'http';
$url = sprintf('%s://%s:%d/api/v1/metrics', $scheme, $host, $port);

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);

$result = curl_exec($ch);
$error = curl_error($ch);
$code = curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
curl_close($ch);

$success = ($error === '' && $code >= 200 && $code < 400);

Logger::log($success ? 'info' : 'error', 'Fluent Bit connectivity test', [
    'host' => $host,
    'port' => $port,
    'tls' => $tls,
    'success' => $success,
    'http_code' => $code,
    'error' => $error,
]);

echo json_encode([
    'success' => $success,
    'http_code' => $code,
    'response' => $result,
    'error' => $error,
]);
