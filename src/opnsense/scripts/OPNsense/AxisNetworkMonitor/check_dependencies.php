#!/usr/local/bin/php
<?php
/**
 * Axis Network Monitor dependency checker.
 */

$dependencies = [
    [
        'id' => 'clickhouse',
        'name' => 'ClickHouse Client',
        'pkg' => 'clickhouse',
        'service' => null,
        'enable_flag' => null,
        'required' => true,
        'description' => 'Columnar analytics engine used for storing events.'
    ],
    [
        'id' => 'redis',
        'name' => 'Redis',
        'pkg' => 'redis',
        'service' => 'redis',
        'enable_flag' => 'redis_enable',
        'required' => true,
        'description' => 'Queue and cache backend for approvals and AI workflows.'
    ],
    [
        'id' => 'fluent-bit',
        'name' => 'Fluent Bit',
        'pkg' => 'fluent-bit',
        'service' => 'fluent-bit',
        'enable_flag' => 'fluent_bit_enable',
        'required' => true,
        'description' => 'Telemetry shipper that forwards OPNsense logs to ClickHouse.'
    ],
    [
        'id' => 'axis-repo',
        'name' => 'Axis Package Repository',
        'pkg' => null,
        'service' => null,
        'required' => false,
        'description' => 'Custom pkg repository providing signed Axis packages.',
        'check' => function () {
            $repoConf = '/usr/local/etc/pkg/repos/axis.conf';
            return is_readable($repoConf);
        }
    ]
];

$result = [
    'timestamp' => gmdate('c'),
    'overall_status' => true,
    'dependencies' => []
];

foreach ($dependencies as $dependency) {
    $status = [
        'id' => $dependency['id'],
        'name' => $dependency['name'],
        'required' => $dependency['required'],
        'description' => $dependency['description'],
        'pkg' => $dependency['pkg'] ?? null,
        'service' => $dependency['service'] ?? null,
        'enable_flag' => $dependency['enable_flag'] ?? null,
        'installed' => null,
        'service_running' => null,
        'service_enabled' => null,
        'status' => 'unknown',
        'message' => ''
    ];

    $installed = null;
    if (!empty($dependency['pkg'])) {
        $pkg = escapeshellarg($dependency['pkg']);
        $cmd = '/usr/sbin/pkg info -e ' . $pkg;
        exec($cmd, $output, $ret);
        $installed = ($ret === 0);
    } elseif (isset($dependency['check']) && is_callable($dependency['check'])) {
        $installed = (bool) $dependency['check']();
    }

    $status['installed'] = ($installed === null) ? null : $installed;

    $serviceRunning = null;
    if (!empty($dependency['service'])) {
        $cmd = '/usr/sbin/service ' . escapeshellarg($dependency['service']) . ' onestatus';
        exec($cmd, $svcOutput, $svcRet);
        $serviceRunning = ($svcRet === 0);
    }

    $status['service_running'] = $serviceRunning;

    if (!empty($dependency['enable_flag'])) {
        $flag = escapeshellarg($dependency['enable_flag']);
        $cmd = '/usr/sbin/sysrc -n ' . $flag;
        exec($cmd, $flagOutput, $flagRet);
        $enabled = null;
        if ($flagRet === 0 && isset($flagOutput[0])) {
            $enabled = strtolower(trim($flagOutput[0])) === 'yes';
        }
        $status['service_enabled'] = $enabled;
    }

    if ($dependency['required']) {
        if ($installed === false) {
            $status['status'] = 'missing';
            $status['message'] = 'Package not installed';
            $result['overall_status'] = false;
        } elseif ($serviceRunning === false) {
            $status['status'] = 'stopped';
            $status['message'] = 'Service is not running';
            $result['overall_status'] = false;
        } else {
            $status['status'] = 'ok';
        }
    } else {
        $status['status'] = $installed ? 'ok' : 'optional-missing';
    }

    $result['dependencies'][] = $status;
}

header('Content-Type: application/json');
echo json_encode($result);
