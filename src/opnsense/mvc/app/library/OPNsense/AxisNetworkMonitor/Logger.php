<?php

namespace OPNsense\AxisNetworkMonitor;

class Logger
{
    private const LOG_FILE = '/var/log/axisnetworkmonitor.log';

    private static function interpolate(string $message, array $context = []): string
    {
        foreach ($context as $key => $value) {
            if (!is_scalar($value)) {
                $value = json_encode($value);
            }
            $message = str_replace('{' . $key . '}', (string)$value, $message);
        }
        return $message;
    }

    public static function log(string $level, string $message, array $context = []): void
    {
        $level = strtoupper($level);
        $timestamp = gmdate('c');
        $interpolated = self::interpolate($message, $context);

        $entry = [
            'ts' => $timestamp,
            'level' => $level,
            'message' => $interpolated,
            'context' => $context,
        ];

        @file_put_contents(self::LOG_FILE, json_encode($entry) . PHP_EOL, FILE_APPEND | LOCK_EX);

        $syslogLevel = LOG_INFO;
        switch ($level) {
            case 'ERROR':
                $syslogLevel = LOG_ERR;
                break;
            case 'WARNING':
            case 'WARN':
                $syslogLevel = LOG_WARNING;
                $level = 'WARNING';
                break;
            case 'NOTICE':
                $syslogLevel = LOG_NOTICE;
                break;
            default:
                $syslogLevel = LOG_INFO;
        }
        openlog('axisnetworkmonitor', LOG_PID | LOG_NDELAY, LOG_USER);
        syslog($syslogLevel, $interpolated);
        closelog();
    }
}
