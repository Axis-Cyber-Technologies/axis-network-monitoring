<?php

namespace OPNsense\AxisNetworkMonitor\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\Core\Backend;
use OPNsense\AxisNetworkMonitor\Logger;

class LogsController extends ApiControllerBase
{
    private const LOG_FILE = '/var/log/axisnetworkmonitor.log';

    public function listAction(): array
    {
        $count = (int)$this->request->get('count', 'int', 200);
        $count = min(max($count, 1), 1000);
        $levelFilter = strtoupper((string)$this->request->get('level', 'striptags', ''));
        $search = trim((string)$this->request->get('q', 'striptags', ''));

        $entries = [];
        if (is_readable(self::LOG_FILE)) {
            $lines = @file(self::LOG_FILE, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [];
            $lines = array_slice($lines, -2000); // limit memory
            foreach (array_reverse($lines) as $line) {
                $decoded = json_decode($line, true);
                if (!is_array($decoded)) {
                    continue;
                }
                if ($levelFilter !== '' && ($decoded['level'] ?? '') !== $levelFilter) {
                    continue;
                }
                if ($search !== '') {
                    $haystack = strtolower(json_encode($decoded));
                    if (strpos($haystack, strtolower($search)) === false) {
                        continue;
                    }
                }
                $entries[] = $decoded;
                if (count($entries) >= $count) {
                    break;
                }
            }
        }

        return [
            'entries' => $entries,
        ];
    }

    public function clearAction(): array
    {
        if (!$this->request->isPost()) {
            return ['success' => false, 'message' => gettext('Invalid method')];
        }
        $backend = new Backend();
        $result = $backend->configdRun('axisnetworkmonitor log-clear');
        Logger::log('notice', 'Log file cleared by user');
        return [
            'success' => true,
            'result' => $result,
        ];
    }
}
