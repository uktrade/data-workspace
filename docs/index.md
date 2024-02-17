---
homepage: true
layout: product
title: Host your own data analysis platform
description: Data Workspace is a PostgreSQL-based open source data analysis platform with features for users with a range of technical skills
image:
  src: /assets/data-workspace-logo-dark-background.svg
  alt: Data Workspace logo of a database with bar charts
startButton:
  href: "development"
  text: Get started
order: 0
---

<div class="govuk-grid-row">
  {% for item in collections.homepage %}
    <section class="govuk-grid-column-one-third-from-desktop govuk-!-margin-bottom-8">
      <h2 class="govuk-heading-m govuk-!-margin-bottom-2">
        <a class="govuk-link govuk-link--no-visited-state" href="{{ item.url }}">{{ item.data.title | smart }}</a>
      </h2>
      <p class="govuk-body">{{ item.data.description | markdown("inline") }}</p>
    </section>
  {% endfor %}
</div>

<div class="govuk-grid-row">

  <section class="govuk-grid-column-full">
    <hr class="govuk-section-break govuk-section-break--visible govuk-section-break--xl govuk-!-margin-top-0">
    <h2 class="govuk-heading-m">Contribute</h2>
    <p class="govuk-body">Data Workspace has been built with features specifically for the Department for Business and Trade. However, we are open to contributions that make it more generic. See the <a href="/contributing/">Contributing page</a>.</p>
  </section>
</div>
