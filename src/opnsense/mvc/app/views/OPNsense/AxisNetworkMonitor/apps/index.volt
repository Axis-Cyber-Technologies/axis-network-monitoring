{% extends "layouts/base.volt" %}

{% block title %}{{ lang._('Axis Network Monitor App Controls') }}{% endblock %}

{% block content %}
<div class="content-box">
    <div class="content-box-main">
        <h2>{{ lang._('Application Controls') }}</h2>
        <p>{{ lang._('This section will allow you to browse, enable, and customize application categories similar to Zenarmor\'s App Controls module.') }}</p>
        <p class="text-muted">{{ lang._('Category datasets, rule editors, and policy bindings are under development.') }}</p>
    </div>
</div>
{% endblock %}
