---
layout: default
permalink: /blog/
title: blog
nav: true
nav_order: 1
pagination:
  enabled: true
  collection: posts
  permalink: /page/:num/
  per_page: 6
  sort_field: date
  sort_reverse: true
  trail:
    before: 1 # The number of links before the current page
    after: 3 # The number of links after the current page
---

<div class="post editorial-blog">

  {% comment %} ---------- Editorial header ---------- {% endcomment %}
  {% assign blog_name_size = site.blog_name | size %}
  {% assign blog_description_size = site.blog_description | size %}
  {% if blog_name_size > 0 or blog_description_size > 0 %}
  <div class="editorial-header">
    <h1 class="editorial-title">{{ site.blog_name }}</h1>
    {% if blog_description_size > 0 %}
      <p class="editorial-tagline">{{ site.blog_description }}</p>
    {% endif %}
  </div>
  {% endif %}

  {% comment %} ---------- Featured row: hero (left) + secondary (right) ---------- {% endcomment %}
  {% assign featured_posts = site.posts | where: "featured", "true" %}
  {% if featured_posts.size > 0 %}
    {% assign hero = featured_posts | first %}
    <div class="featured-row">

      <a class="feature-hero" href="{% if hero.redirect contains '://' %}{{ hero.redirect }}{% else %}{{ hero.url | relative_url }}{% endif %}"{% if hero.redirect contains '://' %} target="_blank" rel="noopener"{% endif %}>
        {% if hero.thumbnail %}
          <div class="feature-hero-img" style="background-image: url('{{ hero.thumbnail | relative_url }}');"></div>
        {% endif %}
        <div class="feature-hero-body">
          {% if hero.categories.size > 0 %}
            <span class="cat-pill">{{ hero.categories | first }}</span>
          {% endif %}
          <h2>{{ hero.title }}</h2>
          <p class="feature-excerpt">{{ hero.description }}</p>
          <p class="feature-meta">
            {% if hero.author %}{{ hero.author }} &nbsp;&middot;&nbsp; {% endif %}{{ hero.date | date: '%b %-d, %Y' }}
          </p>
        </div>
      </a>

      <div class="feature-secondary-col">
        {% for post in featured_posts offset:1 limit:2 %}
          <a class="feature-secondary" href="{% if post.redirect contains '://' %}{{ post.redirect }}{% else %}{{ post.url | relative_url }}{% endif %}"{% if post.redirect contains '://' %} target="_blank" rel="noopener"{% endif %}>
            {% if post.thumbnail %}
              <div class="feature-secondary-img" style="background-image: url('{{ post.thumbnail | relative_url }}');"></div>
            {% endif %}
            <div class="feature-secondary-body">
              {% if post.categories.size > 0 %}
                <span class="cat-pill">{{ post.categories | first }}</span>
              {% endif %}
              <h3>{{ post.title }}</h3>
              <p class="feature-excerpt">{{ post.description }}</p>
              <p class="feature-meta">{{ post.date | date: '%b %-d, %Y' }}</p>
            </div>
          </a>
        {% endfor %}
      </div>

    </div>
  {% endif %}

  {% comment %} ---------- Latest list + sidebar ---------- {% endcomment %}
  <h4 class="section-heading"># Latest</h4>

  <div class="latest-layout">

    {% comment %} ----- main column: post cards ----- {% endcomment %}
    <div class="latest-main">
      <div class="post-cards">
        {% if page.pagination.enabled %}
          {% assign postlist = paginator.posts %}
        {% else %}
          {% assign postlist = site.posts %}
        {% endif %}

        {% for post in postlist %}
          {% assign read_time = post.content | number_of_words | divided_by: 180 | plus: 1 %}
          <a class="post-card" href="{% if post.redirect contains '://' %}{{ post.redirect }}{% else %}{{ post.url | relative_url }}{% endif %}"{% if post.redirect contains '://' %} target="_blank" rel="noopener"{% endif %}>
            {% if post.thumbnail %}
              <div class="post-card-img" style="background-image: url('{{ post.thumbnail | relative_url }}');"></div>
            {% endif %}
            <div class="post-card-body">
              {% if post.categories.size > 0 %}
                <span class="cat-pill">{{ post.categories | first }}</span>
              {% endif %}
              <h3>{{ post.title }}</h3>
              <p class="post-card-excerpt">{{ post.description }}</p>
              <p class="post-card-meta">
                {% if post.author %}{{ post.author }} &nbsp;&middot;&nbsp; {% endif %}
                {{ post.date | date: '%b %-d, %Y' }} &nbsp;&middot;&nbsp; {{ read_time }} min read
              </p>
            </div>
          </a>
        {% endfor %}
      </div>

      {% if page.pagination.enabled %}
        {% include pagination.liquid %}
      {% endif %}
    </div>

    {% comment %} ----- sidebar ----- {% endcomment %}
    <aside class="latest-sidebar">

      {% comment %} Widget: What I'm building (from _data/code.yml) {% endcomment %}
      {% assign code_sections = site.data.code.sections %}
      {% if code_sections and code_sections.size > 0 %}
        <div class="sidebar-widget">
          <h5 class="widget-title">What I'm building</h5>
          {% for section in code_sections %}
            {% for project in section.projects limit: 3 %}
              <a class="widget-project" href="{% if project.package_url %}{{ project.package_url }}{% elsif project.repo %}https://github.com/{{ project.repo }}{% else %}#{% endif %}"{% if project.package_url or project.repo %} target="_blank" rel="noopener"{% endif %}>
                {% if project.package %}<span class="widget-project-name">{{ project.package }}</span>{% endif %}
                <span class="widget-project-desc">{{ project.name }}</span>
                {% if project.date %}<span class="widget-project-date">{{ project.date }}</span>{% endif %}
              </a>
            {% endfor %}
          {% endfor %}
          <a class="widget-more" href="{{ '/code/' | relative_url }}">All code &rarr;</a>
        </div>
      {% endif %}

      {% comment %} Widget: Connect (from _data/socials.yml) {% endcomment %}
      <div class="sidebar-widget">
        <h5 class="widget-title">Connect</h5>
        <div class="widget-socials">
          {% if site.data.socials.github_username %}
            <a href="https://github.com/{{ site.data.socials.github_username }}" target="_blank" rel="noopener" aria-label="GitHub">
              <i class="fa-brands fa-github"></i> GitHub
            </a>
          {% endif %}
          {% if site.data.socials.linkedin_username %}
            <a href="https://www.linkedin.com/in/{{ site.data.socials.linkedin_username }}" target="_blank" rel="noopener" aria-label="LinkedIn">
              <i class="fa-brands fa-linkedin"></i> LinkedIn
            </a>
          {% endif %}
          {% if site.data.socials.email %}
            <a href="mailto:{{ site.data.socials.email }}" aria-label="Email">
              <i class="fa-solid fa-envelope"></i> Email
            </a>
          {% endif %}
          <a href="{{ '/feed.xml' | relative_url }}" aria-label="RSS feed">
            <i class="fa-solid fa-rss"></i> RSS
          </a>
        </div>
      </div>

    </aside>

  </div>

</div>
