{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor Reporting & Data') }}{% endblock %}

{% block content %}
<div class="content-box">
    <div class="content-box-main">
        <h2>{{ lang._('Reporting & Data') }}</h2>
        <p>{{ lang._('Configure data retention, ClickHouse schemas, and export options. Future revisions will expose detailed controls here.') }}</p>
        <p class="text-muted">{{ lang._('In the meantime, use the Activity Log and external analytics tools connected during setup.') }}</p>
    </div>
</div>
{% endblock %}
