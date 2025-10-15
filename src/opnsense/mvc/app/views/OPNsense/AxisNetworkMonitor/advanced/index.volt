{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor Advanced Settings') }}{% endblock %}

{% block content %}
<div class="content-box">
    <div class="content-box-main">
        <h2>{{ lang._('Advanced') }}</h2>
        <p>{{ lang._('Fine-tune automation behaviour, scheduled tasks, and future integrations from this area.') }}</p>
        <p class="text-muted">{{ lang._('Automatic updates, custom scripts, and advanced policy hooks will surface here in later versions.') }}</p>
    </div>
</div>
{% endblock %}
