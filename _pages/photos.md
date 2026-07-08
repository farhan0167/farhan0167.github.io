---
layout: default
permalink: /photos/
title: photography
nav: true
nav_order: 5
---

<div class="post photo-gallery">

  <div class="gallery-header">
    <span class="cat-pill">photos</span>
    <div class="gallery-header-row">
      <h1 class="gallery-title">Photo Gallery</h1>
      {% if site.flickr_feed.tagline %}
        <p class="gallery-tagline">{{ site.flickr_feed.tagline }}</p>
      {% endif %}
    </div>
  </div>

{% assign photos = site.data.flickr_photos %}
{% if photos and photos.size > 0 %}
<div class="photo-grid">
{% for photo in photos %}
<a
          class="photo-tile"
          href="{{ photo.page_url }}"
          target="_blank"
          rel="noopener"
          aria-label="{{ photo.title | default: 'Photo on Flickr' }}"
          style="background-image: url('{{ photo.img_url }}');"
        ></a>
{% endfor %}
</div>
{% else %}
<p class="gallery-empty">No photos yet — check back soon.</p>
{% endif %}

{% if site.flickr_feed.profile_url %}
<div class="gallery-more">
<a class="gallery-more-btn" href="{{ site.flickr_feed.profile_url }}" target="_blank" rel="noopener">View the full photostream on Flickr &rarr;</a>
</div>
{% endif %}

</div>
