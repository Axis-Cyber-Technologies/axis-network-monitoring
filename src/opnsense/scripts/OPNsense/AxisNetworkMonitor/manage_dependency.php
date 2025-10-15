#!/usr/local/bin/php
<?php
/**
 * Manage dependency lifecycle actions (install/start/enable/restart/status).
 */

require_once '/usr/local/opnsense/mvc/app/library/OPNsense/AxisNetworkMonitor/Logger.php';

$deps = [
    'clickhouse' => [
        'pkg' => 'clickhouse',
        'service' => null,
    ],
    'redis' => [
        'pkg' => 'redis',
        'service' => 'redis',
        'enable_sysrc' => 'redis_enable',
    ],
    'fluent-bit' => [
        'pkg' => 'fluent-bit',
        'service' => 'fluent-bit',
        'enable_sysrc' => 'fluent_bit_enable',
    ],
];

$action = $argv[1] ?? '';
$id = $argv[2] ?? '';

$response = [
    'success' => false,
    'action' => $action,
    'id' => $id,
    'messages' => [],
];

if (!isset($deps[$id])) {
    $response['messages'][] = "Unknown dependency: {$id}";
    echo json_encode($response);
    exit(1);
}
$dep = $deps[$id];

function run_cmd(string $cmd): array
{
    $output = [];
    $return = 0;
    exec($cmd . ' 2>&1', $output, $return);
    return [$return, implode("\n", $output)];
}

switch ($action) {
    case 'install':
        if (empty($dep['pkg'])) {
            $response['messages'][] = 'No package defined for install operation.';
            break;
        }
        [$ret, $out] = run_cmd('/usr/sbin/pkg install -y ' . escapeshellarg($dep['pkg']));
        $response['messages'][] = $out;
        $response['success'] = ($ret === 0);
        break;
    case 'enable':
        if (empty($dep['service']) || empty($dep['enable_sysrc'])) {
            $response['messages'][] = 'No service enable flag defined.';
            break;
        }
        [$ret, $out] = run_cmd('/usr/sbin/sysrc ' . escapeshellarg($dep['enable_sysrc'] . '=YES'));
        $response['messages'][] = $out;
        $response['success'] = ($ret === 0);
        break;
    case 'disable':
        if (empty($dep['service']) || empty($dep['enable_sysrc'])) {
            $response['messages'][] = 'No service enable flag defined.';
            break;
        }
        [$ret, $out] = run_cmd('/usr/sbin/sysrc ' . escapeshellarg($dep['enable_sysrc'] . '=NO'));
        $response['messages'][] = $out;
        $response['success'] = ($ret === 0);
        break;
    case 'start':
        if (empty($dep['service'])) {
            $response['messages'][] = 'No service associated with dependency.';
            break;
        }
        [$ret, $out] = run_cmd('/usr/sbin/service ' . escapeshellarg($dep['service']) . ' start');
        $response['messages'][] = $out;
        $response['success'] = ($ret === 0);
        break;
    case 'stop':
        if (empty($dep['service'])) {
            $response['messages'][] = 'No service associated with dependency.';
            break;
        }
        [$ret, $out] = run_cmd('/usr/sbin/service ' . escapeshellarg($dep['service']) . ' stop');
        $response['messages'][] = $out;
        $response['success'] = ($ret === 0);
        break;
    case 'restart':
        if (empty($dep['service'])) {
            $response['messages'][] = 'No service associated with dependency.';
            break;
        }
        [$ret, $out] = run_cmd('/usr/sbin/service ' . escapeshellarg($dep['service']) . ' restart');
        $response['messages'][] = $out;
        $response['success'] = ($ret === 0);
        break;
    case 'status':
        if (empty($dep['service'])) {
            $response['messages'][] = 'No service associated with dependency.';
            break;
        }
        [$ret, $out] = run_cmd('/usr/sbin/service ' . escapeshellarg($dep['service']) . ' onestatus');
        $response['messages'][] = $out;
        $response['success'] = ($ret === 0);
        break;
    default:
        $response['messages'][] = 'Unsupported action. Use install|enable|disable|start|stop|restart|status.';
        break;
}

if (!$response['success']) {
    $response['messages'][] = 'Operation failed or partially successful.';
}


\OPNsense\AxisNetworkMonitor\Logger::log(
    $response['success'] ? 'info' : 'error',
    'Dependency manage command',
    [
        'dependency' => $id,
        'action' => $action,
        'success' => $response['success'],
        'messages' => $response['messages'],
    ]
);

echo json_encode($response);
