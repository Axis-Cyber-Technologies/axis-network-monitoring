<?php

namespace OPNsense\AxisNetworkMonitor;

use OPNsense\Base\IndexController;

class ConfigurationController extends IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/AxisNetworkMonitor/configuration/index');
        $this->view->title = gettext('Axis Network Monitor Configuration');
    }
}
