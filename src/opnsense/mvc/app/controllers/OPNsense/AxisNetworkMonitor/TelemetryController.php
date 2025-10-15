<?php

namespace OPNsense\AxisNetworkMonitor;

use OPNsense\Base\IndexController;

class TelemetryController extends IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/AxisNetworkMonitor/telemetry/index');
        $this->view->title = gettext('Axis Network Monitor Telemetry');
    }
}
