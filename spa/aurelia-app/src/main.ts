import 'bootstrap';
import 'bootstrap/dist/css/bootstrap.css';
import { Aurelia } from 'aurelia-framework';

export function configure(aurelia: Aurelia) {
  aurelia.use
    .standardConfiguration()
    .developmentLogging();

  aurelia.start().then(() => aurelia.setRoot('app'));
}
