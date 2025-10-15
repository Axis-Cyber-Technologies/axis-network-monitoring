import { PLATFORM } from 'aurelia-framework';
import { Router, RouterConfiguration } from 'aurelia-router';

export class App {
  router: Router;

  configureRouter(config: RouterConfiguration, router: Router) {
    config.title = 'Axis Network Monitor';
    config.map([
      { route: ['', 'dashboard'], name: 'dashboard', moduleId: PLATFORM.moduleName('./modules/dashboard/index'), nav: true, title: 'Dashboard' },
      { route: 'status', name: 'status', moduleId: PLATFORM.moduleName('./modules/status/index'), nav: true, title: 'Status' },
      { route: 'reports', name: 'reports', moduleId: PLATFORM.moduleName('./modules/reports/index'), nav: true, title: 'Reports' },
      { route: 'security', name: 'security', moduleId: PLATFORM.moduleName('./modules/security/index'), nav: true, title: 'Security & IDS' },
      { route: 'apps', name: 'apps', moduleId: PLATFORM.moduleName('./modules/apps/index'), nav: true, title: 'App Controls' },
      { route: 'web', name: 'web', moduleId: PLATFORM.moduleName('./modules/web/index'), nav: true, title: 'Web Controls' },
      { route: 'configuration', name: 'configuration', moduleId: PLATFORM.moduleName('./modules/configuration/index'), nav: true, title: 'Configuration' },
      { route: 'advanced', name: 'advanced', moduleId: PLATFORM.moduleName('./modules/advanced/index'), nav: true, title: 'Advanced' }
    ]);
    this.router = router;
  }
}
