{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor Setup') }}{% endblock %}

{% block content %}
    <div class="content-box">
        <div class="content-box-main" data-bind="with: wizard">
            <style>
                .wizard-progress {
                    display: flex;
                    margin-bottom: 20px;
                    gap: 8px;
                }
                .wizard-step {
                    flex: 1;
                    padding: 10px;
                    text-align: center;
                    background-color: #f5f5f5;
                    border-radius: 4px;
                    font-weight: 600;
                    color: #777;
                }
                .wizard-step.active {
                    background-color: #2f5f90;
                    color: #fff;
                }
                .wizard-actions {
                    margin-top: 25px;
                    display: flex;
                    gap: 10px;
                }
                .wizard-actions .btn {
                    min-width: 120px;
                }
            </style>
            <h2>{{ lang._('Axis Network Monitor Setup Wizard') }}</h2>
            <p class="text-muted">
                {{ lang._('Provide connection details for analytics and approval services to finish the initial configuration.') }}
            </p>

            <div class="wizard-progress">
                <div class="wizard-step" data-bind="css: { active: step() === 1 }">1. {{ lang._('Prerequisites') }}</div>
                <div class="wizard-step" data-bind="css: { active: step() === 2 }">2. {{ lang._('General') }}</div>
                <div class="wizard-step" data-bind="css: { active: step() === 3 }">3. {{ lang._('ClickHouse') }}</div>
                <div class="wizard-step" data-bind="css: { active: step() === 4 }">4. {{ lang._('Redis & Queues') }}</div>
                <div class="wizard-step" data-bind="css: { active: step() === 5 }">5. {{ lang._('Summary') }}</div>
            </div>

            <div data-bind="visible: step() === 1">
                <h3>{{ lang._('Preflight Checks') }}</h3>
                <p>{{ lang._('We verified that required packages, services, and hardware resources are available. Resolve any issues before continuing.') }}</p>

                <div class="form-group">
                    <button class="btn btn-default" data-bind="click: refreshPrerequisites, enable: !prereqLoading()">
                        <i class="fa" data-bind="css: prereqLoading() ? 'fa-refresh fa-spin' : 'fa-refresh'"></i>
                        {{ lang._('Re-check Requirements') }}
                    </button>
                </div>

                <div class="alert alert-warning" data-bind="visible: prereqErrors().length > 0">
                    <ul data-bind="foreach: prereqErrors">
                        <li data-bind="text: $data"></li>
                    </ul>
                </div>

                <div class="table-responsive" data-bind="visible: dependencyRows().length > 0">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>{{ lang._('Dependency') }}</th>
                                <th>{{ lang._('Status') }}</th>
                                <th>{{ lang._('Details') }}</th>
                                <th>{{ lang._('Actions') }}</th>
                            </tr>
                        </thead>
                        <tbody data-bind="foreach: dependencyRows">
                            <tr data-bind="css: rowClass">
                                <td>
                                    <strong data-bind="text: name"></strong>
                                    <div class="text-muted" data-bind="text: description"></div>
                                </td>
                                <td data-bind="text: statusText"></td>
                                <td data-bind="text: message"></td>
                                <td>
                                    <button class="btn btn-xs btn-default" data-bind="visible: canInstall, click: install, enable: !busy()">
                                        <i class="fa fa-download"></i> {{ lang._('Install') }}
                                    </button>
                                    <button class="btn btn-xs btn-default" data-bind="visible: canEnable, click: enable, enable: !busy()">
                                        <i class="fa fa-toggle-on"></i> {{ lang._('Enable') }}
                                    </button>
                                    <button class="btn btn-xs btn-default" data-bind="visible: canStart, click: start, enable: !busy()">
                                        <i class="fa fa-play"></i> {{ lang._('Start') }}
                                    </button>
                                    <button class="btn btn-xs btn-default" data-bind="visible: canRestart, click: restart, enable: !busy()">
                                        <i class="fa fa-repeat"></i> {{ lang._('Restart') }}
                                    </button>
                                    <button class="btn btn-xs btn-default" data-bind="visible: canStop, click: stop, enable: !busy()">
                                        <i class="fa fa-stop"></i> {{ lang._('Stop') }}
                                    </button>
                                    <button class="btn btn-xs btn-default" data-bind="visible: canDisable, click: disable, enable: !busy()">
                                        <i class="fa fa-toggle-off"></i> {{ lang._('Disable') }}
                                    </button>
                                    <span data-bind="visible: busy"><i class="fa fa-refresh fa-spin"></i></span>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div class="panel panel-default" data-bind="visible: hardwareData">
                    <div class="panel-heading">
                        <strong>{{ lang._('Detected Hardware') }}</strong>
                    </div>
                    <div class="panel-body">
                        <p>
                            <strong>{{ lang._('CPU') }}:</strong>
                            <span data-bind="text: hardwareSummary().cpu"></span>
                        </p>
                        <p>
                            <strong>{{ lang._('Memory') }}:</strong>
                            <span data-bind="text: hardwareSummary().memory"></span>
                        </p>
                        <p data-bind="visible: matchedProfile">
                            <strong>{{ lang._('Profile Match') }}:</strong>
                            <span data-bind="text: matchedProfile().name"></span>
                        </p>
                    </div>
                    <div class="panel-footer">
                        <strong>{{ lang._('Guidance') }}:</strong>
                        <span data-bind="text: hardwareGuidance"></span>
                    </div>
                </div>

                <h4>{{ lang._('Recommended Hardware Profiles') }}</h4>
                <div class="table-responsive" data-bind="visible: hardwareProfiles().length > 0">
                    <table class="table table-bordered">
                        <thead>
                            <tr>
                                <th>{{ lang._('Profile') }}</th>
                                <th>{{ lang._('Cores') }}</th>
                                <th>{{ lang._('Memory (GB)') }}</th>
                                <th>{{ lang._('Storage (GB)') }}</th>
                                <th>{{ lang._('Description') }}</th>
                            </tr>
                        </thead>
                        <tbody data-bind="foreach: hardwareProfiles">
                            <tr>
                                <td data-bind="text: name"></td>
                                <td data-bind="text: cpu_cores"></td>
                                <td data-bind="text: memory_gb"></td>
                                <td data-bind="text: storage_gb"></td>
                                <td data-bind="text: description"></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <div data-bind="visible: step() === 2">
                <h3>{{ lang._('General Settings') }}</h3>
                <div class="form-group">
                    <label for="friendlyName">{{ lang._('Display name') }}</label>
                    <input id="friendlyName" type="text" class="form-control" data-bind="value: form.general.friendlyName" />
                </div>
                <div class="form-group">
                    <label>{{ lang._('Enable plugin after setup?') }}</label>
                    <div class="checkbox">
                        <label><input type="checkbox" data-bind="checked: form.general.enabled" /> {{ lang._('Enable services on completion') }}</label>
                    </div>
                </div>
            </div>

            <div data-bind="visible: step() === 3">
                <h3>{{ lang._('ClickHouse Analytics Store') }}</h3>
                <div class="form-group">
                    <label for="chHost">{{ lang._('Host') }}</label>
                    <input id="chHost" type="text" class="form-control" data-bind="value: form.clickhouse.host" />
                </div>
                <div class="form-group">
                    <label for="chPort">{{ lang._('HTTP Port') }}</label>
                    <input id="chPort" type="number" class="form-control" data-bind="value: form.clickhouse.port" />
                </div>
                <div class="form-group">
                    <label for="chDb">{{ lang._('Database') }}</label>
                    <input id="chDb" type="text" class="form-control" data-bind="value: form.clickhouse.database" />
                </div>
                <div class="form-group">
                    <label for="chUser">{{ lang._('Username') }}</label>
                    <input id="chUser" type="text" class="form-control" data-bind="value: form.clickhouse.username" />
                </div>
                <div class="form-group">
                    <label for="chPass">{{ lang._('Password') }}</label>
                    <input id="chPass" type="password" class="form-control" data-bind="value: form.clickhouse.password" />
                </div>
                <div class="form-group">
                    <div class="checkbox">
                        <label><input type="checkbox" data-bind="checked: form.clickhouse.useTLS" /> {{ lang._('Use TLS (HTTPS) for ClickHouse connections') }}</label>
                    </div>
                </div>
            </div>

            <div data-bind="visible: step() === 4">
                <h3>{{ lang._('Redis Approval Queue') }}</h3>
                <div class="form-group">
                    <label for="redisHost">{{ lang._('Host') }}</label>
                    <input id="redisHost" type="text" class="form-control" data-bind="value: form.redis.host" />
                </div>
                <div class="form-group">
                    <label for="redisPort">{{ lang._('Port') }}</label>
                    <input id="redisPort" type="number" class="form-control" data-bind="value: form.redis.port" />
                </div>
                <div class="form-group">
                    <label for="redisUser">{{ lang._('Username (optional)') }}</label>
                    <input id="redisUser" type="text" class="form-control" data-bind="value: form.redis.username" />
                </div>
                <div class="form-group">
                    <label for="redisPass">{{ lang._('Password (optional)') }}</label>
                    <input id="redisPass" type="password" class="form-control" data-bind="value: form.redis.password" autocomplete="new-password" />
                </div>
                <div class="form-group">
                    <div class="checkbox">
                        <label><input type="checkbox" data-bind="checked: form.redis.useTLS" /> {{ lang._('Use TLS for Redis connections') }}</label>
                    </div>
                </div>
                <div class="form-group">
                    <div class="checkbox">
                        <label><input type="checkbox" data-bind="checked: form.ingestion.fluentBitEnabled" /> {{ lang._('Fluent Bit agent is deployed to collect telemetry') }}</label>
                    </div>
                </div>
                <div class="form-group">
                    <label for="ingestNotes">{{ lang._('Notes') }}</label>
                    <textarea id="ingestNotes" class="form-control" rows="3" data-bind="value: form.ingestion.notes"></textarea>
                </div>
            </div>

            <div data-bind="visible: step() === 5">
                <h3>{{ lang._('Review & Apply') }}</h3>
                <p>{{ lang._('Confirm the collected values before applying configuration.') }}</p>
                <table class="table table-striped">
                    <tbody>
                        <tr>
                            <th>{{ lang._('Display name') }}</th>
                            <td data-bind="text: form.general.friendlyName"></td>
                        </tr>
                        <tr>
                            <th>{{ lang._('ClickHouse Endpoint') }}</th>
                            <td data-bind="text: clickhouseSummary"></td>
                        </tr>
                        <tr>
                            <th>{{ lang._('Redis Endpoint') }}</th>
                            <td data-bind="text: redisSummary"></td>
                        </tr>
                        <tr>
                            <th>{{ lang._('Enable services') }}</th>
                            <td data-bind="text: enabledSummary"></td>
                        </tr>
                    </tbody>
                </table>
                <div class="alert alert-info">
                    <strong>{{ lang._('Next steps:') }}</strong>
                    <ul>
                        <li>{{ lang._('Deploy the ingestion agents (Fluent Bit) with the configured endpoints.') }}</li>
                        <li>{{ lang._('Verify ClickHouse and Redis connectivity from this appliance.') }}</li>
                        <li>{{ lang._('Continue building dashboards once data is flowing.') }}</li>
                    </ul>
                </div>
            </div>

            <div class="wizard-actions">
                <button class="btn btn-default" data-bind="click: prev, enable: step() > 1">{{ lang._('Back') }}</button>
                <button class="btn btn-primary" data-bind="visible: step() < 5, click: next, enable: canProceed">{{ lang._('Next') }}</button>
                <button class="btn btn-success" data-bind="visible: step() === 5, click: save, css: { disabled: saving() }, enable: !saving()">{{ lang._('Finish Setup') }}</button>
            </div>

            <div class="alert alert-danger" data-bind="visible: errorMessage">
                <strong>{{ lang._('Error:') }}</strong> <span data-bind="text: errorMessage"></span>
            </div>
            <div class="alert alert-success" data-bind="visible: successMessage">
                <strong>{{ lang._('Success:') }}</strong> <span data-bind="text: successMessage"></span>
            </div>
        </div>
    </div>
{% endblock %}

{% block javascript %}
    {{ parent() }}
    <script src="{{ url.getBaseUri() }}js/axisnetworkmonitor/setup.js"></script>
{% endblock %}
