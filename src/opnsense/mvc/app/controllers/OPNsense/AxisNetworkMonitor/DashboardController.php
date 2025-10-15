<?php

namespace OPNsense\AxisNetworkMonitor;

use OPNsense\Base\IndexController;

class DashboardController extends IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/AxisNetworkMonitor/dashboard/index');
        $this->view->title = gettext('Axis Network Monitor Dashboard');
        $this->view->friendlyName = gettext('Axis Network Monitor');
    }
}
