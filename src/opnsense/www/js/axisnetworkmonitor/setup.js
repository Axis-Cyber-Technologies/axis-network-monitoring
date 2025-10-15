(function() {
    function WizardViewModel() {
        var self = this;

        self.step = ko.observable(1);
        self.saving = ko.observable(false);
        self.errorMessage = ko.observable('');
        self.successMessage = ko.observable('');

        self.prereqLoading = ko.observable(false);
        self.prereqErrors = ko.observableArray([]);
        self.dependencyRows = ko.observableArray([]);
        self.hardwareData = ko.observable(null);
        self.hardwareProfiles = ko.observableArray([]);
        self.matchedProfile = ko.observable(null);
        self.prereqOk = ko.observable(false);

        self.form = {
            general: {
                friendlyName: ko.observable('Axis Network Monitor'),
                enabled: ko.observable(true),
                onboot: ko.observable(true)
            },
            clickhouse: {
                host: ko.observable('localhost'),
                port: ko.observable(8123),
                database: ko.observable('axis_monitor'),
                username: ko.observable('axis_api'),
                password: ko.observable(''),
                useTLS: ko.observable(false)
            },
            redis: {
                host: ko.observable('localhost'),
                port: ko.observable(6379),
                username: ko.observable(''),
                password: ko.observable(''),
                useTLS: ko.observable(false)
            },
            ingestion: {
                fluentBitEnabled: ko.observable(true),
                notes: ko.observable('')
            }
        };

        function DependencyRow(parent, data) {
            var row = this;
            row.vm = parent;
            row.id = data.id;
            row.name = data.name;
            row.description = data.description;
            row.required = data.required;
            row.pkg = data.pkg || null;
            row.service = data.service || null;
            row.status = data.status || 'unknown';
            row.message = data.message || '';
            row.installed = data.installed;
            row.service_running = data.service_running;
            row.service_enabled = data.service_enabled;
            row.suggested = data.suggested || null;
            row.busy = ko.observable(false);

            row.statusText = ko.computed(function() {
                switch (row.status) {
                    case 'ok':
                        return gettext('Ready');
                    case 'missing':
                        return gettext('Missing');
                    case 'stopped':
                        return gettext('Stopped');
                    case 'optional-missing':
                        return gettext('Optional - not installed');
                    default:
                        return gettext('Unknown');
                }
            });

            row.rowClass = ko.computed(function() {
                return {
                    'success': row.status === 'ok',
                    'danger': row.status === 'missing' || row.status === 'stopped',
                    'warning': row.status === 'optional-missing',
                    'info': ['ok', 'missing', 'stopped', 'optional-missing'].indexOf(row.status) === -1
                };
            });

            row.canInstall = ko.computed(function() {
                return !!row.pkg && row.installed === false;
            });
            row.canEnable = ko.computed(function() {
                return !!row.service && (row.service_enabled === false || row.service_enabled === null);
            });
            row.canStart = ko.computed(function() {
                return !!row.service && row.installed !== false && row.service_running === false;
            });
            row.canRestart = ko.computed(function() {
                return !!row.service && row.service_running === true;
            });
            row.canStop = ko.computed(function() {
                return !!row.service && row.service_running === true;
            });
            row.canDisable = ko.computed(function() {
                return !!row.service && row.service_enabled === true;
            });
            row.hasSuggested = ko.computed(function() {
                return !!row.suggested;
            });

            row.install = function() {
                parent.dependencyCommand(row, 'install');
            };
            row.enable = function() {
                parent.dependencyCommand(row, 'enable');
            };
            row.disable = function() {
                parent.dependencyCommand(row, 'disable');
            };
            row.start = function() {
                parent.dependencyCommand(row, 'start');
            };
            row.restart = function() {
                parent.dependencyCommand(row, 'restart');
            };
            row.stop = function() {
                parent.dependencyCommand(row, 'stop');
            };
            row.applySuggested = function() {
                if (row.suggested) {
                    parent.applySuggestion(row.id, row.suggested);
                }
            };
        }

        self.hardwareSummary = ko.computed(function() {
            var hw = self.hardwareData();
            if (!hw) {
                return { cpu: gettext('Unknown'), memory: gettext('Unknown') };
            }
            var cpu = hw.cpu_model + ' (' + hw.cpu_cores + ' ' + gettext('cores') + ')';
            var memory = hw.memory_gb ? hw.memory_gb + ' GB' : gettext('Unknown');
            return { cpu: cpu, memory: memory };
        });

        self.hardwareGuidance = ko.computed(function() {
            var match = self.matchedProfile();
            if (match && match.description) {
                return match.description;
            }
            return gettext('Consider upgrading hardware to meet minimum specifications.');
        });

        self.clickhouseSummary = ko.computed(function() {
            var scheme = self.form.clickhouse.useTLS() ? 'https://' : 'http://';
            return scheme + self.form.clickhouse.host() + ':' + self.form.clickhouse.port() + '/' + self.form.clickhouse.database();
        });

        self.redisSummary = ko.computed(function() {
            var scheme = self.form.redis.useTLS() ? 'rediss://' : 'redis://';
            var credentials = self.form.redis.username() ? self.form.redis.username() + '@' : '';
            return scheme + credentials + self.form.redis.host() + ':' + self.form.redis.port();
        });

        self.enabledSummary = ko.computed(function() {
            return self.form.general.enabled() ? gettext('Yes') : gettext('No');
        });
        self.onbootSummary = ko.computed(function() {
            return self.form.general.onboot() ? gettext('Yes') : gettext('No');
        });

        self.canProceed = ko.computed(function() {
            return self.validateStep(self.step());
        });

        self.next = function() {
            if (self.validateStep(self.step())) {
                self.step(self.step() + 1);
                self.errorMessage('');
            }
        };

        self.prev = function() {
            if (self.step() > 1) {
                self.step(self.step() - 1);
                self.errorMessage('');
            }
        };

        self.validateStep = function(step) {
            switch (step) {
                case 1:
                    return self.prereqOk();
                case 2:
                    return self.form.general.friendlyName().trim().length > 0;
                case 3:
                    return self.form.clickhouse.host().trim().length > 0 &&
                        !!self.form.clickhouse.port() &&
                        self.form.clickhouse.database().trim().length > 0 &&
                        self.form.clickhouse.username().trim().length > 0;
                case 4:
                    return self.form.redis.host().trim().length > 0 && !!self.form.redis.port();
                default:
                    return true;
            }
        };

        self.collectPayload = function() {
            return {
                axisnetworkmonitor: {
                    general: {
                        enabled: self.form.general.enabled() ? '1' : '0',
                        onboot: self.form.general.onboot() ? '1' : '0',
                        friendlyName: self.form.general.friendlyName(),
                        configured: '1'
                    },
                    clickhouse: {
                        host: self.form.clickhouse.host(),
                        port: String(self.form.clickhouse.port()),
                        database: self.form.clickhouse.database(),
                        username: self.form.clickhouse.username(),
                        password: self.form.clickhouse.password(),
                        useTLS: self.form.clickhouse.useTLS() ? '1' : '0'
                    },
                    redis: {
                        host: self.form.redis.host(),
                        port: String(self.form.redis.port()),
                        username: self.form.redis.username(),
                        password: self.form.redis.password(),
                        useTLS: self.form.redis.useTLS() ? '1' : '0'
                    },
                    ingestion: {
                        fluentBitEnabled: self.form.ingestion.fluentBitEnabled() ? '1' : '0',
                        notes: self.form.ingestion.notes()
                    }
                }
            };
        };

        self.save = function() {
            if (!self.validateStep(4)) {
                return;
            }
            self.saving(true);
            self.errorMessage('');
            self.successMessage('');

            var payload = self.collectPayload();

            $.ajax({
                url: '/api/axisnetworkmonitor/settings/set',
                type: 'post',
                data: payload,
                success: function(resp) {
                    if (resp && resp.result === 'ok') {
                        self.markComplete();
                    } else if (resp && resp.validations) {
                        var messages = [];
                        Object.keys(resp.validations).forEach(function(key) {
                            messages.push(resp.validations[key]);
                        });
                        self.errorMessage(messages.join(', '));
                        self.saving(false);
                    } else {
                        self.errorMessage(gettext('Unexpected response from server.'));
                        self.saving(false);
                    }
                },
                error: function(xhr) {
                    self.errorMessage(xhr.responseText || gettext('Failed to save configuration.'));
                    self.saving(false);
                }
            });
        };

        self.markComplete = function() {
            $.ajax({
                url: '/api/axisnetworkmonitor/settings/complete',
                type: 'post',
                data: {
                    enabled: self.form.general.enabled() ? '1' : '0'
                },
                success: function() {
                    self.successMessage(gettext('Setup complete. Reloading...'));
                    setTimeout(function() { window.location.reload(); }, 1200);
                },
                error: function(xhr) {
                    self.errorMessage(xhr.responseText || gettext('Failed to finalize configuration.'));
                },
                complete: function() {
                    self.saving(false);
                }
            });
        };

        self.load = function() {
            $.getJSON('/api/axisnetworkmonitor/settings/get', function(data) {
                if (data && data.axisnetworkmonitor) {
                    var mdl = data.axisnetworkmonitor;
                    if (mdl.general) {
                        self.form.general.friendlyName(mdl.general.friendlyName || 'Axis Network Monitor');
                        self.form.general.enabled(mdl.general.enabled === '1');
                        self.form.general.onboot(mdl.general.onboot === '1');
                    }
                    if (mdl.clickhouse) {
                        self.form.clickhouse.host(mdl.clickhouse.host || 'localhost');
                        self.form.clickhouse.port(parseInt(mdl.clickhouse.port || 8123, 10));
                        self.form.clickhouse.database(mdl.clickhouse.database || 'axis_monitor');
                        self.form.clickhouse.username(mdl.clickhouse.username || 'axis_api');
                        self.form.clickhouse.password(mdl.clickhouse.password || '');
                        self.form.clickhouse.useTLS(mdl.clickhouse.useTLS === '1');
                    }
                    if (mdl.redis) {
                        self.form.redis.host(mdl.redis.host || 'localhost');
                        self.form.redis.port(parseInt(mdl.redis.port || 6379, 10));
                        self.form.redis.username(mdl.redis.username || '');
                        self.form.redis.password(mdl.redis.password || '');
                        self.form.redis.useTLS(mdl.redis.useTLS === '1');
                    }
                    if (mdl.ingestion) {
                        self.form.ingestion.fluentBitEnabled(mdl.ingestion.fluentBitEnabled !== '0');
                        self.form.ingestion.notes(mdl.ingestion.notes || '');
                    }
                }
            });
            self.refreshPrerequisites();
        };

        self.refreshPrerequisites = function() {
            self.prereqLoading(true);
            self.prereqErrors.removeAll();
            self.dependencyRows([]);
            self.hardwareData(null);
            self.hardwareProfiles([]);
            self.matchedProfile(null);
            $.getJSON('/api/axisnetworkmonitor/settings/prerequisites', function(resp) {
                var deps = [];
                var ok = false;
                if (resp && resp.dependencies && resp.dependencies.dependencies) {
                    resp.dependencies.dependencies.forEach(function(item) {
                        deps.push(new DependencyRow(self, item));
                    });
                    ok = resp.dependencies.overall_status === true;
                }
                self.dependencyRows(deps);
                deps.forEach(function(row) {
                    if (row.id === 'redis' && row.suggested) {
                        self.applySuggestion('redis', row.suggested);
                    }
                    if (row.id === 'clickhouse' && row.suggested) {
                        self.applySuggestion('clickhouse', row.suggested);
                    }
                });
                self.prereqOk(ok);

                if (resp && resp.hardware && resp.hardware.hardware) {
                    self.hardwareData(resp.hardware.hardware);
                    self.hardwareProfiles(resp.hardware.profiles || []);
                    self.matchedProfile(resp.hardware.matched_profile || null);
                }

                if (resp && Array.isArray(resp.errors)) {
                    resp.errors.forEach(function(err) { self.prereqErrors.push(err); });
                }

                if (!ok && deps.length === 0) {
                    self.prereqErrors.push(gettext('No dependency information available.')); 
                }
            }).fail(function() {
                self.prereqErrors.push(gettext('Failed to retrieve prerequisite status.'));
                self.prereqOk(false);
            }).always(function() {
                self.prereqLoading(false);
            });
        };

        self.dependencyCommand = function(row, action) {
            row.busy(true);
            $.ajax({
                url: '/api/axisnetworkmonitor/settings/dependency/' + encodeURIComponent(row.id),
                type: 'post',
                data: { action: action },
            }).done(function(resp) {
                if (!resp || resp.success === false) {
                    var msg = (resp && (resp.message || resp.messages)) ? (resp.message || resp.messages) : gettext('Command failed.');
                    self.prereqErrors.push(row.name + ': ' + msg);
                }
            }).fail(function(xhr) {
                self.prereqErrors.push(row.name + ': ' + (xhr.responseText || gettext('Command failed.')));
            }).always(function() {
                row.busy(false);
                setTimeout(function() { self.refreshPrerequisites(); }, 1000);
            });
        };

        self.applySuggestion = function(id, suggestion) {
            if (!suggestion) {
                return;
            }
            if (id === 'redis') {
                if (!self.form.redis.host() || self.form.redis.host() === 'localhost') {
                    self.form.redis.host(suggestion.host || '127.0.0.1');
                }
                if (!self.form.redis.port() || self.form.redis.port() === 0) {
                    self.form.redis.port(suggestion.port || 6379);
                }
                if (typeof suggestion.use_tls !== 'undefined') {
                    self.form.redis.useTLS(!!suggestion.use_tls);
                }
            } else if (id === 'clickhouse') {
                if (!self.form.clickhouse.host()) {
                    self.form.clickhouse.host(suggestion.host || '127.0.0.1');
                }
                if (!self.form.clickhouse.port() || self.form.clickhouse.port() === 0) {
                    self.form.clickhouse.port(suggestion.port || 8123);
                }
                if (typeof suggestion.use_tls !== 'undefined') {
                    self.form.clickhouse.useTLS(!!suggestion.use_tls);
                }
            }
        };

        self.clickhouseTestStatus = {
            running: ko.observable(false),
            message: ko.observable(''),
            success: ko.observable(null)
        };

        self.redisTestStatus = {
            running: ko.observable(false),
            message: ko.observable(''),
            success: ko.observable(null)
        };

        self.testClickhouse = function() {
            self.clickhouseTestStatus.running(true);
            self.clickhouseTestStatus.message('');
            self.clickhouseTestStatus.success(null);
            $.ajax({
                url: '/api/axisnetworkmonitor/settings/testClickhouse',
                type: 'post',
                data: {
                    host: self.form.clickhouse.host(),
                    port: self.form.clickhouse.port(),
                    user: self.form.clickhouse.username(),
                    password: self.form.clickhouse.password(),
                    tls: self.form.clickhouse.useTLS() ? 1 : 0
                }
            }).done(function(resp) {
                if (resp && resp.success) {
                    self.clickhouseTestStatus.success(true);
                    self.clickhouseTestStatus.message(gettext('Connection successful.'));
                } else {
                    self.clickhouseTestStatus.success(false);
                    self.clickhouseTestStatus.message((resp && resp.error) || gettext('Connection failed.'));
                }
            }).fail(function(xhr) {
                self.clickhouseTestStatus.success(false);
                self.clickhouseTestStatus.message(xhr.responseText || gettext('Connection failed.'));
            }).always(function() {
                self.clickhouseTestStatus.running(false);
            });
        };

        self.testRedis = function() {
            self.redisTestStatus.running(true);
            self.redisTestStatus.message('');
            self.redisTestStatus.success(null);
            $.ajax({
                url: '/api/axisnetworkmonitor/settings/testRedis',
                type: 'post',
                data: {
                    host: self.form.redis.host(),
                    port: self.form.redis.port(),
                    password: self.form.redis.password()
                }
            }).done(function(resp) {
                if (resp && resp.success) {
                    self.redisTestStatus.success(true);
                    self.redisTestStatus.message(gettext('Redis responded: ') + (resp.response || 'PONG'));
                } else {
                    self.redisTestStatus.success(false);
                    self.redisTestStatus.message((resp && resp.response) || gettext('Connection failed.'));
                }
            }).fail(function(xhr) {
                self.redisTestStatus.success(false);
                self.redisTestStatus.message(xhr.responseText || gettext('Connection failed.'));
            }).always(function() {
                self.redisTestStatus.running(false);
            });
        };
    }

    window.addEventListener('DOMContentLoaded', function() {
        var vm = {
            wizard: new WizardViewModel()
        };
        ko.applyBindings(vm);
        vm.wizard.load();
    });
})();
