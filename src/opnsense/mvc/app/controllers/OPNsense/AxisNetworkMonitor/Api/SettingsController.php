<?php

namespace OPNsense\AxisNetworkMonitor\Api;

use OPNsense\Base\ApiMutableModelControllerBase;
use OPNsense\AxisNetworkMonitor\AxisNetworkMonitor;
use OPNsense\AxisNetworkMonitor\Logger;
use OPNsense\Core\Config;
use OPNsense\Core\Backend;

class SettingsController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\AxisNetworkMonitor\AxisNetworkMonitor';
    protected static $internalModelName = 'axisnetworkmonitor';

    public function statusAction(): array
    {
        $model = $this->getModel();
        $general = $model->general->getNodes();

        $hasClickHouse =
            !empty((string)$model->clickhouse->host) &&
            !empty((string)$model->clickhouse->database) &&
            !empty((string)$model->clickhouse->username);

        $hasRedis = !empty((string)$model->redis->host);

        $configured = ($model->general->configured->__toString() === '1') && $hasClickHouse && $hasRedis;

        return [
            'configured' => $configured,
            'enabled' => (string)$general['enabled'] === '1',
            'friendlyName' => (string)$general['friendlyName'],
        ];
    }

    public function prerequisitesAction(): array
    {
        $backend = new Backend();
        $response = [
            'dependencies' => null,
            'hardware' => null,
            'overall_ok' => false,
            'errors' => []
        ];

        $depRaw = $backend->configdRun('axisnetworkmonitor dependency-status');
        $depJson = json_decode($depRaw, true);
        if (is_array($depJson)) {
            $response['dependencies'] = $depJson;
            if (!empty($depJson['overall_status'])) {
                $response['overall_ok'] = (bool)$depJson['overall_status'];
            }
        } else {
            $response['errors'][] = gettext('Unable to retrieve dependency status.');
        }

        $hwRaw = $backend->configdRun('axisnetworkmonitor hardware-profile');
        $hwJson = json_decode($hwRaw, true);
        if (is_array($hwJson)) {
            $response['hardware'] = $hwJson;
        } else {
            $response['errors'][] = gettext('Unable to retrieve hardware profile.');
        }

        return $response;
    }

    public function dependencyAction($id = null): array
    {
        if (!$this->request->isPost()) {
            return ['success' => false, 'message' => gettext('Invalid method')];
        }

        $action = $this->request->getPost('action', 'striptags', '');
        $allowed = ['install', 'enable', 'disable', 'start', 'stop', 'restart', 'status'];

        if (empty($id) || !in_array($action, $allowed, true)) {
            return ['success' => false, 'message' => gettext('Unsupported dependency action.')];
        }

        $backend = new Backend();
        $result = $backend->configdRun(sprintf('axisnetworkmonitor dependency-manage %s %s', escapeshellarg($action), escapeshellarg($id)));
        $decoded = json_decode($result, true);
        if (is_array($decoded)) {
            Logger::log(
                ($decoded['success'] ?? false) ? 'info' : 'error',
                'Dependency command executed',
                [
                    'dependency' => $id,
                    'action' => $action,
                    'success' => $decoded['success'] ?? false,
                ]
            );
            return $decoded;
        }

        return [
            'success' => false,
            'message' => gettext('Failed to execute dependency command.'),
            'raw' => $result,
        ];
    }

    /**
     * Persist wizard completion state.
     */
    public function completeAction(): array
    {
        if ($this->request->isPost()) {
            $model = $this->getModel();
            $model->general->configured = "1";
            $model->general->enabled = $this->request->getPost('enabled', 'striptags', '1');
            $this->saveModel($model);
            Logger::log('notice', 'Setup wizard completed', [
                'enabled' => $model->general->enabled->__toString(),
                'clickhouse_host' => (string)$model->clickhouse->host,
                'redis_host' => (string)$model->redis->host,
            ]);
            return ['status' => 'ok'];
        }

        return ['status' => 'failed'];
    }

    public function setAction($uuid = null)
    {
        $model = $this->getModel();
        $previousEnabled = $model->general->enabled->__toString();
        $result = parent::setAction($uuid);
        if (is_array($result) && ($result['result'] ?? null) === 'ok') {
            $model = $this->getModel();
            Logger::log('info', 'Configuration updated', [
                'clickhouse_host' => (string)$model->clickhouse->host,
                'redis_host' => (string)$model->redis->host,
            ]);
            $newEnabled = $model->general->enabled->__toString();
            if ($previousEnabled !== $newEnabled) {
                $backend = new Backend();
                $backend->configdRun(sprintf('axisnetworkmonitor enable-toggle %s', $newEnabled === '1' ? 'enable' : 'disable'));
            }
        }
        return $result;
    }

    private function saveModel(AxisNetworkMonitor $model): void
    {
        $model->serializeToConfig();
        Config::getInstance()->save();
    }
}

    public function testClickhouseAction(): array
    {
        if (!$this->request->isPost()) {
            return ['success' => false, 'message' => gettext('Invalid method')];
        }
        $host = $this->request->getPost('host', 'striptags', '127.0.0.1');
        $port = $this->request->getPost('port', 'int', 8123);
        $user = $this->request->getPost('user', 'striptags', '');
        $password = $this->request->getPost('password', null, '');
        $tls = $this->request->getPost('tls', 'int', 0) ? 'true' : 'false';

        $backend = new Backend();
        $cmd = sprintf(
            'axisnetworkmonitor clickhouse-test %s %s %s %s %s',
            escapeshellarg($host),
            escapeshellarg((string)$port),
            escapeshellarg($user),
            escapeshellarg($password ?? ''),
            escapeshellarg($tls)
        );
        $json = $backend->configdRun($cmd);
        $data = json_decode($json, true);
        if (is_array($data)) {
            return $data;
        }
        return ['success' => false, 'message' => gettext('Unable to parse ClickHouse test result.'), 'raw' => $json];
    }

    public function testRedisAction(): array
    {
        if (!$this->request->isPost()) {
            return ['success' => false, 'message' => gettext('Invalid method')];
        }
        $host = $this->request->getPost('host', 'striptags', '127.0.0.1');
        $port = $this->request->getPost('port', 'int', 6379);
        $password = $this->request->getPost('password', null, '');

        $backend = new Backend();
        $cmd = sprintf(
            'axisnetworkmonitor redis-test %s %s %s',
            escapeshellarg($host),
            escapeshellarg((string)$port),
            escapeshellarg($password ?? '')
        );
        $json = $backend->configdRun($cmd);
        $data = json_decode($json, true);
        if (is_array($data)) {
            return $data;
        }
        return ['success' => false, 'message' => gettext('Unable to parse Redis test result.'), 'raw' => $json];
    }

    public function testFluentbitAction(): array
    {
        if (!$this->request->isPost()) {
            return ['success' => false, 'message' => gettext('Invalid method')];
        }
        $host = $this->request->getPost('host', 'striptags', '127.0.0.1');
        $port = $this->request->getPost('port', 'int', 2021);
        $tls = $this->request->getPost('tls', 'int', 0) ? 'true' : 'false';

        $backend = new Backend();
        $cmd = sprintf(
            'axisnetworkmonitor fluentbit-test %s %s %s',
            escapeshellarg($host),
            escapeshellarg((string)$port),
            escapeshellarg($tls)
        );
        $json = $backend->configdRun($cmd);
        $data = json_decode($json, true);
        if (is_array($data)) {
            return $data;
        }
        return ['success' => false, 'message' => gettext('Unable to parse Fluent Bit test result.'), 'raw' => $json];
    }

    public function interfacesAction(): array
    {
        $result = [];
        $config = Config::getInstance()->object();
        if (isset($config->interfaces)) {
            foreach ($config->interfaces as $ifaceName => $iface) {
                $descr = (string)($iface->descr ?? $ifaceName);
                $result[] = [
                    'name' => (string)$ifaceName,
                    'description' => $descr,
                ];
            }
        }
        return $result;
    }
