---
layout: page
permalink: /code/
title: code
description: projects that I am working on
nav: true
nav_order: 4
---

<style>
  .code-table {
    table-layout: fixed;
    width: 100%;
  }
  .code-table td,
  .code-table th {
    overflow-wrap: break-word;
    word-break: normal;
    white-space: normal;
  }
</style>

{% for section in site.data.code.sections %}

## {{ section.title }}

<table class="table table-sm code-table w-100">
  <colgroup>
    <col style="width: 18%;">
    <col style="width: 52%;">
    <col style="width: 16%;">
    <col style="width: 14%;">
  </colgroup>
  <thead>
    <tr>
      <th scope="col">Date</th>
      <th scope="col">Project</th>
      <th scope="col">Package</th>
      <th scope="col">GitHub</th>
    </tr>
  </thead>
  <tbody>
    {% for project in section.projects %}
    <tr>
      <td class="align-middle">{{ project.date }}</td>
      <td class="align-middle">{{ project.name }}</td>
      <td class="align-middle">
        {% if project.package %}
          {% if project.package_url %}
            <a href="{{ project.package_url }}">{{ project.package }}</a>
          {% else %}
            {{ project.package }}
          {% endif %}
        {% endif %}
      </td>
      <td class="align-middle">
        {% if project.repo %}
          <a class="github-button" href="https://github.com/{{ project.repo }}" data-icon="octicon-star" data-show-count="true" aria-label="Star {{ project.repo }} on GitHub">Star</a>
        {% endif %}
      </td>
    </tr>
    {% endfor %}
  </tbody>
</table>

{% endfor %}

<!-- GitHub star buttons: renders live star counts -->
<script async defer src="https://buttons.github.io/buttons.js"></script>
