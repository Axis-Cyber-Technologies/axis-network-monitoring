(function() {
    'use strict';

    var AxisSpa = {
        init: function() {
            var root = document.getElementById('axis-spa-root');
            if (!root) {
                return;
            }
            root.innerHTML = '' +
                '<div class="panel panel-default axis-spa-placeholder">' +
                '  <div class="panel-heading">' +
                '    <h3 class="panel-title">Axis Network Monitor Dashboard (Preview)</h3>' +
                '  </div>' +
                '  <div class="panel-body">' +
                '    <p>This area will host the Aurelia-based dashboard with live metrics, status, and controls.</p>' +
                '    <p class="text-muted">Development is in progress to mirror the full Sensei experience without subscription components.</p>' +
                '    <ul>' +
                '      <li>Click the navigation items on the left to explore configuration placeholders.</li>' +
                '      <li>Use the Setup Wizard to change connection settings or re-run prerequisites.</li>' +
                '      <li>Operational logs remain available below for troubleshooting.</li>' +
                '    </ul>' +
                '  </div>' +
                '</div>';
        }
    };

    document.addEventListener('DOMContentLoaded', function() {
        AxisSpa.init();
    });
})();
