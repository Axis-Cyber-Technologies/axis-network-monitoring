{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor Security & IDS') }}{% endblock %}

{% block content %}
<div class="content-box">
    <div class="content-box-main">
        <h2>{{ lang._('Security & Intrusion Detection') }}</h2>
        <p>{{ lang._('This section will centralize intrusion detection, threat intelligence, and policy orchestration controls.') }}</p>
        <p class="text-muted">{{ lang._('Integration with Suricata, policy orchestration, and alerting will be delivered in forthcoming updates.') }}</p>
    </div>
</div>
{% endblock %}
