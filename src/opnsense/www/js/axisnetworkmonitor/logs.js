(function() {
    function LogsViewModel() {
        var self = this;
        self.entries = ko.observableArray([]);
        self.levelFilter = ko.observable('');
        self.searchQuery = ko.observable('');
        self.count = ko.observable(200);
        self.loading = ko.observable(false);
        self.clearing = ko.observable(false);
        self.errorMessage = ko.observable('');

        self.refresh = function() {
            self.loading(true);
            self.errorMessage('');
            $.getJSON('/api/axisnetworkmonitor/logs/list', {
                level: self.levelFilter(),
                q: self.searchQuery(),
                count: self.count()
            }).done(function(resp) {
                self.entries(resp.entries || []);
            }).fail(function(xhr) {
                self.errorMessage(xhr.responseText || gettext('Failed to load logs.'));
            }).always(function() {
                self.loading(false);
            });
        };

        self.clear = function() {
            if (!confirm(gettext('Clear all Axis Network Monitor logs?'))) {
                return;
            }
            self.clearing(true);
            $.post('/api/axisnetworkmonitor/logs/clear', {})
                .done(function() {
                    self.entries([]);
                    self.refresh();
                })
                .fail(function(xhr) {
                    self.errorMessage(xhr.responseText || gettext('Failed to clear logs.'));
                })
                .always(function() {
                    self.clearing(false);
                });
        };

        self.init = function() {
            self.refresh();
        };
    }

    window.addEventListener('DOMContentLoaded', function() {
        var root = document.getElementById('axis-monitor-root');
        if (!root) {
            return;
        }
        var vm = {
            logs: new LogsViewModel()
        };
        ko.applyBindings(vm, root);
        vm.logs.init();
    });
})();
