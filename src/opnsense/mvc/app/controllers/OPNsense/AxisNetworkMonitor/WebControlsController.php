<?php

namespace OPNsense\AxisNetworkMonitor;

use OPNsense\Base\IndexController;

class WebControlsController extends IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/AxisNetworkMonitor/web/index');
        $this->view->title = gettext('Axis Network Monitor Web Controls');
    }
}
