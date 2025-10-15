<?php

namespace OPNsense\AxisNetworkMonitor;

use OPNsense\Base\IndexController;

class SecurityController extends IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/AxisNetworkMonitor/security/index');
        $this->view->title = gettext('Axis Network Monitor Security & IDS');
    }
}
