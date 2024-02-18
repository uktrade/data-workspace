const govukEleventyPlugin = require('@x-govuk/govuk-eleventy-plugin')
const fs = require('fs')

module.exports = function(eleventyConfig) {
  eleventyConfig.addPlugin(govukEleventyPlugin, {
    icons: {
      shortcut: '/assets/dit-favicon.png'
    },
    header: {
      logotype: {
        html: fs.readFileSync('./docs/assets/dit-logo.svg', {encoding: 'utf8'})
      },
      productName: 'Data Workspace (developer documentation)',
      search: {
        indexPath: '/search.json',
        sitemapPath: '/sitemap'
      }
    },
    footer: {
        meta: {
          items: [
            {
              href: 'https://github.com/uktrade/data-workspace',
              text: 'Data Workspace GitHub repository'
            },
            {
              href: 'https://www.gov.uk/government/organisations/department-for-business-and-trade',
              text: 'Created by the Department for Business and Trade (DBT)'
            }
          ]
        }
      }
  })

eleventyConfig.addCollection('homepage', (collection) =>
    collection
      .getFilteredByGlob([
        'docs/development.md',
        'docs/deployment.md',
        'docs/data-ingestion.md'
      ])
      .sort((a, b) => (a.data.order || 0) - (b.data.order || 0))
  )
  eleventyConfig.addCollection('deployment', (collection) =>
    collection
      .getFilteredByGlob(['docs/deployment/*.md'])
      .sort((a, b) => (a.data.order || 0) - (b.data.order || 0))
  )
  eleventyConfig.addCollection('development', (collection) =>
    collection
      .getFilteredByGlob(['docs/development/*.md'])
      .sort((a, b) => (a.data.order || 0) - (b.data.order || 0))
  )
  eleventyConfig.addCollection('architecture', (collection) =>
    collection
      .getFilteredByGlob(['docs/architecture/*.md'])
      .sort((a, b) => (a.data.order || 0) - (b.data.order || 0))
  )
  eleventyConfig.addCollection('architecture-decision-record', (collection) =>
    collection
      .getFilteredByGlob(['docs/architecture-decision-record/*.md'])
      .sort((a, b) => (a.data.order || 0) - (b.data.order || 0))
  )

  eleventyConfig.addPassthroughCopy('./docs/assets')
  eleventyConfig.addPassthroughCopy('./docs/CNAME')
  eleventyConfig.addPassthroughCopy('./docs/development/assets')
  eleventyConfig.addPassthroughCopy({'./node_modules/mermaid/dist/**.mjs': 'assets/mermaid'})
  eleventyConfig.addPassthroughCopy({'./node_modules/mermaid/dist/**.js': 'assets/mermaid'})

  return {
    dataTemplateEngine: 'njk',
    htmlTemplateEngine: 'njk',
    markdownTemplateEngine: 'njk',
    dir: {
      // Use layouts from the plugin
      input: 'docs',
      layouts: '../node_modules/@x-govuk/govuk-eleventy-plugin/layouts'
    }
  }
};
