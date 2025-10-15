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
        $allowed = ['install', 'enable', 'start', 'restart', 'status'];

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
