{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor Telemetry') }}{% endblock %}

{% block content %}
<div class="content-box">
    <div class="content-box-main">
        <h2>{{ lang._('Telemetry') }}</h2>
        <p>{{ lang._('Monitor Fluent Bit health and manage ingestion agent status from this page. Additional charts and service controls will be added soon.') }}</p>
        <p class="text-muted">{{ lang._('For now, review the telemetric configuration via the Setup Wizard and ensure Fluent Bit agents are forwarding data.') }}</p>
    </div>
</div>
{% endblock %}
