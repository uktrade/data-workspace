# Infrastructure file naming and resource grouping standards

This folder contains the definitions of the Terraform (AWS) resources that make up a Data Workspace environment, and this document explains the rules that govern how these resources should be grouped into what files, and how those files should be named.

> [!IMPORTANT]
> For historical (or accidental) reasons, some of the infrastructure defined in this folder does not adhere to the rules described below. Please do not take this as a reason to not follow the rules. Please adhere to the rules in all but the most exceptional circumstances.

---

### Contents

- [1) File naming](#1-file-naming)
- [2) Modules](#2-modules)
- [3) Security groups](#3-security-groups)
- [4) IAM-related resources](#4-iam-related-resources)

---

## 1) File naming

Files should be named according to the pattern:

```
[feature index][resource group index]-[feature][optional dash-separated sub-feature breadcrumb]--[resource group].tf
```

For example, for file `0811-airflow-team-dag-processor--ecs.tf` the components of the file name are:

- **Feature index**: `08`
- **Resource group index**: `11`
- **Feature**: `airflow`
- **Optional dash-separated sub-feature breadcrumb**: `team-dag-processor`, where in this case the sub-feature is `team` and its sub-sub-feature is `dag-processor`
- **Resource group**: `ecs`

What each of the four components of the name mean are explained below.

#### 1a) Feature / Feature index

A _feature_ defines most, but not strictly all, of the resources relating to a high level feature of Data Workspace. There is no perfect definition of a feature, but if users or stakeholders refer to it, and to make it work you need to fire up a certain group of resources used exclusively by it, it has a fairly limited interface/surface that users or other features access, then it can probably be usefully classed as a feature. Often a feature is a single ECS service along with all of its supporting infrastructure, but this is not necessarily true in all cases.

The _feature index_ is the two-digit index of the feature in the list of all features. If there are related features, choose indexes so that they are grouped together. To achieve this files may have to be re-indexed in bulk when a related feature is added, but since this is rare, this is fine.

There are exceptions that do not strictly adhere to this definition:

- Feature index `01` defines inputs and config, and has a slightly different naming pattern: without `--[resource-group]`.
- Feature index `02` defines the `core` feature that that defines resources used by many other features.
- Feature index `98` contains legacy resources — resources that are in the process of being removed, but need multiple steps or or manual intervention. For example, if a resource needs deletion protection removed, or if a bucket needs to be emptied.
- Feature index `99` contains `moved` resources that assist in moving Terraform resources without destroying and re-creating them, and has a slightly different naming pattern: without `--[resource-group]`, similar to feature index `01`.

#### 1b) Optional dash-separated sub-feature breadcrumb

Some features are complex and have multiple levels of sub-features. For example Airflow has a webserver and a scheduler that each require a number of different types of resources, and so to make this clear in the file structure and to avoid too many resources per file, they are split to sub-features, and the "breadcrumb" of feature and sub-feature names placed into the file names.

In some cases it's not obvious if something should be a high level feature just related to another feature, or a sub-feature of that feature. To decide, if a feature realistically cannot be used without another feature, or if the feature uses a high number of resources that would be usually classed as "internal" to another feature, then it likely makes a feature/sub-feature relationship.

Note that the names of sub-features _can_ themselves have dashes — this is fine since sub-features can be inferred by looking at adjacent files.

#### 1c) Resouce group name / resource group index

A _resource group_ is the core AWS-level name that groups related resources that are used in a (sub-)feature. For example, a file ending in `--lb.tf` would would contain AWS resource relating to the load balancer(s) needed by a particular (sub-)feature.

The _resource group index_ is the two-digit index of the file from the start of its top-level feature. It is chosen so that within a (sub-)feature resources in the higher numbered files can refer to resources in the lower numbered files, but _not_ the other way around. For example for a given (sub-)feature, because an ECS service would refer to a load balancer, ECS-related resources would go in an `--ecs.tf` file with with a _higher_ index than resources in `--lb.tf`. This puts the resources in a (sub-)feature into a fairly "layered" structure: building from lower-level layers, often VPC or database-related, up to the higher-level layers, such as ECS-related resources that refer to the VPC or database resources. It also means that resources in different (sub-)features have a familiar structure in terms of their contents and ordering.

There are no rules that govern how resources within a specific file must be ordered. Try to have the "main" resources near the top of the file, and to group related resources together, but there is no perfect way that is helpful in all cases.


## 2) Modules

Do not use modules to wrap a feature. Modules should only be used to avoid repetition/boilerplate on the AWS-level and are so fairly low level.

For example, a current module that follows this is [security_group_client_server_connections](./modules/security_group_client_server_connections/), which is used to reduce some of the boilerplate when defining security group rules.

While this results in a lot of files in a single folder, it means that it's easy to have an at-a-glance/birds-eye view of all the infrastructure of Data Workspace. The naming pattern means that features can be worked on in parallel by multiple teams without stepping on each other's toes very often (although admittedly not never).


## 3) Security groups

Security groups are tricky because they link different resources often in different features, and there is often no unique way of defining them. To keep a consistent structure in their definitions:

#### 3a) Define security groups close to their associated resource

Place definitions of security groups in close to the definition of the resources that is assigned them. In most cases the same file as the resource is defined is appropriate. This is because security groups are extremely pervasive in AWS architecture and tightly coupled to the the resource they are associated with — many resources, no matter the conceptual level in the architecture, has a security group associated with it.

In the rare case that there is no resource, a `--sg.tf` file should be created for this.

#### 3b) Define all security group rules near the client side of the relationship

Place both ingress and egress security group rules next to the security group definition of the _client_ side of the relationship, i.e. the one that needs the egress rule. In the rare case that there is no client security group, for example if exposing a server to a CIDR, then a separate file ending in `--sg.tf` file should be made for these rules (possibly via a prefix list).

Having the rules defined on the client side rather than the server side means it's clear to where data can be sent, especially from tools. For example, this makes it clear that tools can communicate with and send data to the datasets database, the CloudWatch VPC endpoint, and so on.

#### 3c) Use the existing module to define security group rules

Ideally use the [security_group_client_server_connections](./module/security_group_client_server_connection) module to create the rules. If it's not suitable for a particular case, consider extending it.

#### 3d) Do not share security groups between different resources

It can be tempting to assign the same security group to different resources, especially if when they're added they are share the same rules. For clarity and to keep things friendly to future changes, create a new security group for each resource.

This includes when using `count` or `for_each`  to quickly create instantiate multiple resources - you can similarly use `count` or `for_each` on the security groups to assign each of them a unique security group.

#### 3e) Do not assign multiple security groups to a single resource

Although AWS supports having multiple security groups assigned to a single resource, this adds an unnecessary layer of complexity. Do not do this, and just have a single security group on any resource.

#### 3f) Define security groups and rules at the top level, not from modules

Security groups and their rules should be defined at the top level, and not inside modules (other than by using [security_group_client_server_connections](./module/security_group_client_server_connection)). While this might introduce a degree of verbosity or repetition, what is allowed to communicate with what is a core property of the infrastructure to surface, for example to create or update network diagrams.

This approach also makes modules flexible — for example by easily allowing security group rules to be different depending on which VPC the modules created by the resource run in. It also follows [Hashicorp's recommended pattern of modules being passed dependencies rather than creating them](https://developer.hashicorp.com/terraform/language/modules/develop/composition#dependency-inversion).


## 4) IAM-related resources

In most cases IAM-related resources, for example roles and policies, should be in the same file as the resource that uses them. This is because, similar to security groups, they are fairly pervasive — as in many resources at different "levels" of AWS-architecture have IAM roles and policies associated with them. They are also extremely tightly coupled to these resources — what a resource is allowed to do is a key property of that resource.

An exception is if the IAM-related resources are used in multiple (sub-)features. In this case it is likely appropriate to have a `--iam.tf` file that defines the IAM-related resources.
