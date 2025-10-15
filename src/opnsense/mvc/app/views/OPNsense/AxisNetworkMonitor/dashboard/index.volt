{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor Dashboard') }}{% endblock %}

{% block content %}
    <div class="content-box">
        <div class="content-box-main">
            <div class="pull-right">
                <a class="btn btn-primary" href="/ui/axisnetworkmonitor/general/">{{ lang._('Launch Setup Wizard') }}</a>
            </div>
            <h2>{{ friendlyName }}</h2>
            <p>{{ lang._('The single-page dashboard is under active development. Use the navigation menu to explore upcoming sections or revisit the Setup Wizard to adjust configuration.') }}</p>
            <div id="axis-spa-root"></div>
        </div>
    </div>

    <div class="content-box" id="axis-monitor-log-root">
        <div class="content-box-main" data-bind="with: logs">
            <h3>{{ lang._('Activity Log') }}</h3>
            <div class="panel panel-default">
                <div class="panel-heading">
                    <button class="btn btn-xs btn-default pull-right" data-bind="click: refresh, enable: !loading()">
                        <i class="fa" data-bind="css: loading() ? 'fa-refresh fa-spin' : 'fa-refresh'"></i>
                        {{ lang._('Refresh') }}
                    </button>
                    <button class="btn btn-xs btn-default pull-right" style="margin-right:5px;" data-bind="click: clear, enable: !clearing()">
                        <i class="fa fa-trash"></i> {{ lang._('Clear Log') }}
                    </button>
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
    <script src="{{ url.getBaseUri() }}js/axisnetworkmonitor/axis-vendor.js"></script>
    <script src="{{ url.getBaseUri() }}js/axisnetworkmonitor/axis-app.js"></script>
    <script src="{{ url.getBaseUri() }}js/axisnetworkmonitor/logs.js"></script>
{% endblock %}
