<?php

namespace OPNsense\AxisNetworkMonitor;

use OPNsense\Base\IndexController;

class AppControlsController extends IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/AxisNetworkMonitor/apps/index');
        $this->view->title = gettext('Axis Network Monitor App Controls');
    }
}
