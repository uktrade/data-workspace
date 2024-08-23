<p align="center">
  <img alt="Data Workspace logo" width="130" height="160" src="./docs/assets/data-workspace-logo-colour-for-light-background.svg">
</p>

<p align="center"><strong>Data Workspace</strong> <em>- a PostgreSQL-based open source data analysis platform</em></p>

---

This is the entry-point repository for Data Workspace, a PostgreSQL-based open source data analysis platform with features for users with a range of technical skills. It contains a brief catalogue of all Data Workspace repositories (below), the source for the [Data Workspace developer documentation](https://data-workspace.docs.trade.gov.uk/), and the Terraform code to deploy Data Workspace into AWS.

> [!TIP]
> Looking for the Data Workspace Django application? It's now in the [data-workspace-frontend repo](https://github.com/uktrade/data-workspace-frontend).

---

### Catalogue of Data Workspace repositories

The components of Data Workspace are stored across several Git repositories.

#### Core

- [data-workspace](https://github.com/uktrade/data-workspace) (this repository)

   Contains the Terraform code to deploy Data Workspace in AWS, and the public facing developer documentation for Data Workspace. See [Contents of this repository](#contents-of-this-repository) for details of what goes where.

- [data-workspace-frontend](https://github.com/uktrade/data-workspace-frontend)

   Contains the core Django application the defines the most user-facing components of Data Workspace. Also contains "the proxy" that sits in front of the Django application that integrates with SSO and routes requests, for example to tools.

   Also contains the Dockerfiles for other components. However, it's planned to move these out to separate repositories.


#### Tools

- [data-workspace-tools](https://github.com/uktrade/data-workspace-tools)

  Contains the definitions of the on-demand tools that users can launch in Data Workspace.

- [data-workspace-mlflow](https://github.com/uktrade/data-workspace-mlflow)

  Contains the definitions of MLFlow, an MLOps tool.

- [data-workspace-superset](https://github.com/uktrade/data-workspace-superset)

  Contains the definitions of Superset, a dashboarding tool.

- [data-workspace-gitlab](https://github.com/uktrade/data-workspace-gitlab)

  Contains the definitions of GitLab, which stores code and run CI pipelines.

- [data-workspace-arangodb](https://github.com/uktrade/data-workspace-arangodb)

  Contains the definitions of ArangoDB, a graph database


#### Low level

Some of the components of Data Workspace are lower level, and less Data Workspace-specific - they can at least theorically be re-used outside of Data Workspace

- [pg-sync-roles](https://github.com/uktrade/pg-sync-roles)

   Used to synchronise permissions between the data-workspace-frontend metadata database and users in the main PostgreSQL database.

- [mobius3](https://github.com/uktrade/mobius3)

   Used in on-demand tools to sync user's files with S3

- [dns-rewrite-proxy](https://github.com/uktrade/dns-rewrite-proxy)

   Used in tools in order to filter and re-write DNS requests

- [theia-postgres](https://github.com/uktrade/theia-postgres)

   Used in Theia to give reasonably straightforward access to a PostgreSQL database

- [mirror-git-to-s3](https://github.com/uktrade/mirror-git-to-s3)<br>
  [git-lfs-http-mirror](https://github.com/uktrade/git-lfs-http-mirror)

   Used to mirror git repositories that use Large File Storage (LFS) to S3 and to then access them from inside tools.

- [ecs-pipeline](https://github.com/uktrade/ecs-pipeline)

   Used to deploy Data Workspace from Jenkins

- [quicksight-bulk-update-datasets](https://github.com/uktrade/quicksight-bulk-update-datasets)

   A CLI script to make bulk updates to Amazon Quicksight datasets


#### Ingesting data

These components are usually used to ingest data into the PostgreSQL database that's the core of Data Workspace

- [pg-bulk-ingest](https://github.com/uktrade/pg-bulk-ingest)<br>
  [pg-force-execute](https://github.com/uktrade/pg-force-execute)
   
   Used to ingest large amounts of data in the PostgreSQL database

- [to-file-like-obj](https://github.com/uktrade/to-file-like-obj)

   Used in serveral ways to convery from iterables of bytes to a file-like object for memory-efficient data ingestion. For example when parsing CSVs.

- [iterable-subprocess](https://github.com/uktrade/iterable-subprocess)

   Used to extract data from archives in a format that requires running an external program.

- [stream-read-ods](https://github.com/uktrade/stream-read-ods)

   Used to extract data from Open Document Spreadsheet (ODS) files in a memory-efficient and disk-efficient way.

- [stream-unzip](https://github.com/uktrade/stream-unzip)

   Used to extract data from ZIP files in a memory-efficient and disk-efficient way.

- [stream-read-xbrl](https://github.com/uktrade/stream-read-xbrl)

   Used to ingest data from Companies House.

- [sqlite-s3vfs](https://github.com/uktrade/sqlite-s3vfs)

   Used to generate large and complex SQLite files that are then ingested into the Data Workspace PostgreSQL database.

- [s3-dropbox](https://github.com/uktrade/s3-dropbox)

   Used to power a simple API to accept incoming data files in any format and drop it in S3, subsequently ingested into Data Workspace.


#### Publishing data

These components are used when publishing data from Data Workspace.

- [public-data-api](https://github.com/uktrade/public-data-api)

   Makes data available to the public.

- [stream-zip](https://github.com/uktrade/stream-zip)

   Creates ZIP files in a memory-efficient and disk-efficient way.

- [stream-write-ods](https://github.com/uktrade/stream-write-ods)

   Creates Open Document Spreadsheet (ODS) files in a memory-efficient and disk-efficient way.

- [postgresql-proxy](https://github.com/uktrade/postgresql-proxy)

   Part of the system that makes data available to other internal applications.

---

### Contents of this repository

- [.github/workflows/](.github/workflows/)

   The [GitHub actions](https://docs.github.com/en/actions) workflows for this repository.

   - [deploy-docs-to-github-pages.yml](./.github/workflows/deploy-docs-to-github-pages.yml)

      On change of the main branch (such as a merge of a PR) it builds the developer documentation in [docs/](./docs/), pushes it to [GitHub pages](https://pages.github.com/), and surfaces it at https://data-workspace.docs.trade.gov.uk/

   - [lint-terraform.yml](./.github/workflows/lint-terraform.yml)

      On any PR against the main branch, or change of the main branch, it runs linting checks against the Terraform code to make sure it is consistently formatted.

- [.gitignore](./.gitignore)

   A list of file patterns that are not committed to this repository by default during local development. For example it contains the patterns that match temporary files created by Terraform when run locally, or the built documentation when building the documentation locally.

- [docs/](./docs/)

   The source of the [Data Workspace developer documentation](https://data-workspace.docs.trade.gov.uk/). The documentation is built using the node-based [Eleventy static site generator](https://www.11ty.dev/) and the [X-GOVUK govuk-eleventy-plugin](https://x-govuk.github.io/govuk-eleventy-plugin/) in order to use the GOV.UK design system.

   The built documentation is hosted on [GitHub pages](https://pages.github.com/).

- [package-lock.json](./package-lock.json)<br>
  [package.json](./package.json)<br>
  [eleventy.config.js](./eleventy.config.js)

   Supporting files for building the Data Workspace developer documentation. The `package.json` file has the list of direct dependencies, `package-lock.json` has specific versions of all the direct and transitive node dependencies, and `eleventy.config.js` contains the configuration.

- [infra/](./infra/)

   The [Terraform](https://www.terraform.io/) source to build the infrastructure of Data Workspace in Amazon Web Services (AWS).

- [README.md](./README.md)

   The source of the file you're currently reading.

- [CODEOWNERS](./CODEOWNERS)

   The list of [code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) that can approve pull requests in this repository.
