#!/usr/local/bin/php
<?php
/**
 * Collect basic hardware information and match against recommended profiles.
 */

function sysctl_value(string $name): ?string
{
    $output = shell_exec('/sbin/sysctl -n ' . escapeshellarg($name));
    if ($output === null) {
        return null;
    }
    return trim($output);
}

$cpuModel = sysctl_value('hw.model') ?? 'Unknown';
$cpuCores = (int) (sysctl_value('hw.ncpu') ?? 0);
$memBytes = (int) (sysctl_value('hw.physmem') ?? 0);

$stats = [
    'cpu_model' => $cpuModel,
    'cpu_cores' => $cpuCores,
    'memory_bytes' => $memBytes,
    'memory_gb' => $memBytes > 0 ? round($memBytes / 1024 / 1024 / 1024, 1) : null,
    'uptime_seconds' => (int) (sysctl_value('kern.boottime') ?? 0)
];

$profiles = [
    [
        'id' => 'minimum',
        'name' => 'Minimum',
        'cpu_cores' => 2,
        'memory_gb' => 4,
        'storage_gb' => 40,
        'description' => 'Suitable for small branch offices or lab environments (up to ~50 devices).'
    ],
    [
        'id' => 'recommended',
        'name' => 'Recommended',
        'cpu_cores' => 4,
        'memory_gb' => 8,
        'storage_gb' => 120,
        'description' => 'Balanced deployment for midsize networks (50-250 devices).'
    ],
    [
        'id' => 'enterprise',
        'name' => 'Enterprise',
        'cpu_cores' => 8,
        'memory_gb' => 16,
        'storage_gb' => 240,
        'description' => 'For large campuses, multi-site deployments, or heavy analytics workloads.'
    ]
];

$matchedProfile = null;
foreach (array_reverse($profiles) as $profile) {
    $meetsCpu = $cpuCores >= $profile['cpu_cores'];
    $meetsMem = ($stats['memory_gb'] ?? 0) >= $profile['memory_gb'];
    if ($meetsCpu && $meetsMem) {
        $matchedProfile = $profile;
        break;
    }
}

$response = [
    'timestamp' => gmdate('c'),
    'hardware' => $stats,
    'profiles' => $profiles,
    'matched_profile' => $matchedProfile
];

echo json_encode($response);
