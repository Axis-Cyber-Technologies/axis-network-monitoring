{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor Configuration') }}{% endblock %}

{% block content %}
<div class="content-box">
    <div class="content-box-main">
        <h2>{{ lang._('Configuration') }}</h2>
        <p>{{ lang._('Manage global settings such as display name, service enablement, and integrations. Updates made here are saved immediately.') }}</p>
        <p class="text-muted">{{ lang._('Detailed configuration forms will be added in upcoming iterations. For now, revisit the Setup Wizard to adjust parameters.') }}</p>
        <a class="btn btn-primary" href="/ui/axisnetworkmonitor/general/">{{ lang._('Launch Setup Wizard') }}</a>
    </div>
</div>
{% endblock %}
