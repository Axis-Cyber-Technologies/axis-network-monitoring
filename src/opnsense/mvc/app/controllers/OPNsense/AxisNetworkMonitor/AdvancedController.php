<?php

namespace OPNsense\AxisNetworkMonitor;

use OPNsense\Base\IndexController;

class AdvancedController extends IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/AxisNetworkMonitor/advanced/index');
        $this->view->title = gettext('Axis Network Monitor Advanced Settings');
    }
}
