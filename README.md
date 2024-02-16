# data-workspace

This is the core repository for Data Workspace, an open source data analysis platform with features for users with a range of technical skills. It contains the source for the [Data Workspace technical documentation](https://data-workspace.docs.trade.gov.uk/), and the Terraform code to deploy Data Workspace into AWS.

> [!TIP]
> Looking for the Data Workspace Django application? It's now in the [data-workspace-frontend repo](https://github.com/uktrade/data-workspace-frontend).


## Catalogue of Data Workspace repositories

The components of Data Workspace are stored across several Git repositories.

### Core

- [data-workspace](https://github.com/uktrade/data-workspace) (this repository)

   Contains the Terraform code to deploy Data Workspace in AWS, and the public facing technical documentation for Data Workspace.

- [data-workspace-frontend](https://github.com/uktrade/data-workspace-frontend)

   Contains the core Django application the defines the most user-facing components of Data Workspace. Also contains "the proxy" that sits in front of the Django application that integrates with SSO and routes requests, for example to tools.

   Also contains the Dockerfiles for other components such as GitLab, Superset, MLFlow, and services relating to metrics. However, it's planned to move these out to separate repositories.


### Tools

- [data-workspace-tools](https://github.com/uktrade/data-workspace-tools)

  Contains the definitions of the on-demand tools that users can launch in Data Workspace.


### Low level

Some of the components of Data Workspace are lower level, and less Data Workspace-specific - they can at least theorically be re-used outside of Data Workspace

- [mobius3](https://github.com/uktrade/mobius3)

   Used in on-demand tools to sync user's files with S3

- [dns-rewrite-proxy](https://github.com/uktrade/dns-rewrite-proxy)

   Used in tools in order to filter and re-write DNS requests

- [theia-postgres](https://github.com/uktrade/theia-postgres)

   Used in Theia to give reasonably straightforward access to a PostgreSQL database

- [ecs-pipeline](https://github.com/uktrade/ecs-pipeline)

   Used to deploy Data Workspace from Jenkins

