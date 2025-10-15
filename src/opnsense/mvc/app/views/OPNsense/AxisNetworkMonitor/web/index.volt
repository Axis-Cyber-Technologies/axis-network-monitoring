{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor Web Controls') }}{% endblock %}

{% block content %}
<div class="content-box">
    <div class="content-box-main">
        <h2>{{ lang._('Web Controls') }}</h2>
        <p>{{ lang._('URL categorization, custom web rules, and safe-search enforcement will live here to mirror Zenarmor\'s Web Controls module.') }}</p>
        <p class="text-muted">{{ lang._('We will surface category lists and policy mappings in future iterations.') }}</p>
    </div>
</div>
{% endblock %}
