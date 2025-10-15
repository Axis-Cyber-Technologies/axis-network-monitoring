<?php

namespace OPNsense\AxisNetworkMonitor;

use OPNsense\Base\IndexController;

class ReportsController extends IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/AxisNetworkMonitor/reports/index');
        $this->view->title = gettext('Axis Network Monitor Reporting & Data');
    }
}
