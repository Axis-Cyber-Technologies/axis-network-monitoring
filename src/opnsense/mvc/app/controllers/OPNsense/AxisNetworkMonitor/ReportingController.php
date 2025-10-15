<?php

namespace OPNsense\AxisNetworkMonitor;

use OPNsense\Base\IndexController;

class ReportingController extends IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/AxisNetworkMonitor/reporting/index');
        $this->view->title = gettext('Axis Network Monitor Reporting & Data');
    }
}
