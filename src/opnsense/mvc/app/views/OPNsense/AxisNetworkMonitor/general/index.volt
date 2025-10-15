{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor') }}{% endblock %}

{% block content %}
    <div class="content-box" id="axis-monitor-root">
        <div class="content-box-main">
            <h2>{{ friendlyName }}</h2>
            <p>{{ greeting }}</p>
            <p class="text-muted">
                {{ lang._('Setup is complete. Continue by adding dashboards, data sources, and policy workflows.') }}
            </p>

            <div class="panel panel-default" data-bind="with: logs">
                <div class="panel-heading">
                    <strong>{{ lang._('Activity Log') }}</strong>
                    <div class="pull-right">
                        <button class="btn btn-xs btn-default" data-bind="click: refresh, enable: !loading()">
                            <i class="fa" data-bind="css: loading() ? 'fa-refresh fa-spin' : 'fa-refresh'"></i>
                            {{ lang._('Refresh') }}
                        </button>
                        <button class="btn btn-xs btn-default" data-bind="click: clear, enable: !clearing()">
                            <i class="fa fa-trash"></i> {{ lang._('Clear Log') }}
                        </button>
                    </div>
                    <div class="clearfix"></div>
                </div>
                <div class="panel-body">
                    <div class="row">
                        <div class="col-md-3">
                            <label>{{ lang._('Level') }}</label>
                            <select class="form-control" data-bind="value: levelFilter, event: { change: refresh }">
                                <option value="">{{ lang._('All') }}</option>
                                <option value="INFO">INFO</option>
                                <option value="NOTICE">NOTICE</option>
                                <option value="WARNING">WARNING</option>
                                <option value="ERROR">ERROR</option>
                            </select>
                        </div>
                        <div class="col-md-5">
                            <label>{{ lang._('Search') }}</label>
                            <input type="text" class="form-control" data-bind="value: searchQuery, valueUpdate: 'afterkeydown'" />
                        </div>
                        <div class="col-md-2">
                            <label>{{ lang._('Max entries') }}</label>
                            <input type="number" min="1" max="1000" class="form-control" data-bind="value: count" />
                        </div>
                        <div class="col-md-2">
                            <label>&nbsp;</label>
                            <button class="btn btn-primary btn-block" data-bind="click: refresh, enable: !loading()">{{ lang._('Apply') }}</button>
                        </div>
                    </div>

                    <div class="table-responsive" style="margin-top:15px;" data-bind="visible: entries().length > 0">
                        <table class="table table-striped table-condensed">
                            <thead>
                                <tr>
                                    <th>{{ lang._('Time (UTC)') }}</th>
                                    <th>{{ lang._('Level') }}</th>
                                    <th>{{ lang._('Message') }}</th>
                                </tr>
                            </thead>
                            <tbody data-bind="foreach: entries">
                                <tr>
                                    <td data-bind="text: ts"></td>
                                    <td data-bind="text: level"></td>
                                    <td>
                                        <div data-bind="text: message"></div>
                                        <pre class="small" data-bind="visible: context && Object.keys(context).length, text: JSON.stringify(context, null, 2)"></pre>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <div class="alert alert-info" data-bind="visible: entries().length === 0 && !loading()">
                        {{ lang._('No log entries yet.') }}
                    </div>
                    <div class="alert alert-warning" data-bind="visible: errorMessage">
                        <strong>{{ lang._('Error:') }}</strong> <span data-bind="text: errorMessage"></span>
                    </div>
                </div>
            </div>
        </div>
    </div>
{% endblock %}

{% block javascript %}
    {{ parent() }}
    <script src="{{ url.getBaseUri() }}js/axisnetworkmonitor/logs.js"></script>
{% endblock %}
