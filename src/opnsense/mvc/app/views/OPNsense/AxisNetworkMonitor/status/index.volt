{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor Status') }}{% endblock %}

{% block content %}
<div class="content-box">
    <div class="content-box-main">
        <h2>{{ lang._('Service Status') }}</h2>
        <p>{{ lang._('A comprehensive status panel will appear here, showing the health of collectors, queues, and analytics backends.') }}</p>
        <p class="text-muted">{{ lang._('For now, use the dashboard log viewer and setup wizard to monitor dependency health.') }}</p>
    </div>
</div>
{% endblock %}
