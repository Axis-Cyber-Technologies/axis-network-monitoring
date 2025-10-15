<?php

namespace OPNsense\AxisNetworkMonitor;

use OPNsense\Base\IndexController;

class StatusController extends IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/AxisNetworkMonitor/status/index');
        $this->view->title = gettext('Axis Network Monitor Status');
    }
}
