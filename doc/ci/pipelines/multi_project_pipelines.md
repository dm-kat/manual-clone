---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Multi-project pipelines **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/199224) to GitLab Free in 12.8.

You can set up [GitLab CI/CD](../index.md) across multiple projects, so that a pipeline
in one project can trigger a [downstream](downstream_pipelines.md) pipeline in another project. You can visualize the entire pipeline
in one place, including all cross-project interdependencies.

For example, you might deploy your web application from three different projects in GitLab.
Each project has its own build, test, and deploy process. With multi-project pipelines you can
visualize the entire pipeline, including all build and test stages for all three projects.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see the [Multi-project pipelines demo](https://www.youtube.com/watch?v=g_PIwBM1J84).

Multi-project pipelines are also useful for larger products that require cross-project interdependencies, like those
with a [microservices architecture](https://about.gitlab.com/blog/2016/08/16/trends-in-version-control-land-microservices/).
Learn more in the [Cross-project Pipeline Triggering and Visualization demo](https://about.gitlab.com/learn/)
at GitLab@learn, in the Continuous Integration section.

If you trigger a pipeline in a downstream private project, on the upstream project's pipelines page,
you can view:

- The name of the project.
- The status of the pipeline.

If you have a public project that can trigger downstream pipelines in a private project,
make sure there are no confidentiality problems.

## Create multi-project pipelines

To create multi-project pipelines, you can:

- [Define them in your `.gitlab-ci.yml` file](#define-multi-project-pipelines-in-your-gitlab-ciyml-file).
- [Use the API](#create-multi-project-pipelines-by-using-the-api).

### Define multi-project pipelines in your `.gitlab-ci.yml` file

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/199224) to GitLab Free in 12.8.

When you use the [`trigger`](../yaml/index.md#trigger) keyword to create a multi-project
pipeline in your `.gitlab-ci.yml` file, you create what is called a *trigger job*. For example:

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger: my/deployment
```

In this example, after the `rspec` job succeeds in the `test` stage,
the `staging` trigger job starts. The initial status of this
job is `pending`.

GitLab then creates a downstream pipeline in the
`my/deployment` project and, as soon as the pipeline is created, the
`staging` job succeeds. The full path to the project is `my/deployment`.

You can view the status for the pipeline, or you can display
[the downstream pipeline's status instead](downstream_pipelines.md#mirror-the-status-of-a-downstream-pipeline-in-the-trigger-job).

The user that creates the upstream pipeline must be able to create pipelines in the
downstream project (`my/deployment`) too. If the downstream project is not found,
or the user does not have [permission](../../user/permissions.md) to create a pipeline there,
the `staging` job is marked as _failed_.

#### Trigger job configuration limitations

Trigger jobs can use only a limited set of the GitLab CI/CD [configuration keywords](../yaml/index.md).
The keywords available for use in trigger jobs are:

- [`trigger`](../yaml/index.md#trigger)
- [`stage`](../yaml/index.md#stage)
- [`allow_failure`](../yaml/index.md#allow_failure)
- [`rules`](../yaml/index.md#rules)
- [`only` and `except`](../yaml/index.md#only--except)
- [`when`](../yaml/index.md#when) (only with a value of `on_success`, `on_failure`, or `always`)
- [`extends`](../yaml/index.md#extends)
- [`needs`](../yaml/index.md#needs), but not [`needs:project`](../yaml/index.md#needsproject)

Trigger jobs cannot use [job-level persisted variables](../variables/where_variables_can_be_used.md#persisted-variables).

#### Specify a downstream pipeline branch

You can specify a branch name for the downstream pipeline to use.
GitLab uses the commit on the head of the branch to
create the downstream pipeline.

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  stage: deploy
  trigger:
    project: my/deployment
    branch: stable-11-2
```

Use:

- The `project` keyword to specify the full path to a downstream project.
  In [GitLab 15.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/367660), variable expansion is
  supported.
- The `branch` keyword to specify the name of a branch in the project specified by `project`.
  In [GitLab 12.4 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/10126), variable expansion is
  supported.

Pipelines triggered on a protected branch in a downstream project use the [role](../../user/permissions.md)
of the user that ran the trigger job in the upstream project. If the user does not
have permission to run CI/CD pipelines against the protected branch, the pipeline fails. See
[pipeline security for protected branches](index.md#pipeline-security-on-protected-branches).

#### Pass artifacts to a downstream pipeline

You can pass artifacts to a downstream pipeline by using [`needs:project`](../yaml/index.md#needsproject).

1. In a job in the upstream pipeline, save the artifacts using the [`artifacts`](../yaml/index.md#artifacts) keyword.
1. Trigger the downstream pipeline with a trigger job:

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   deploy:
     stage: deploy
     trigger: my/downstream_project
   ```

1. In a job in the downstream pipeline, fetch the artifacts from the upstream pipeline
   by using `needs:project`. Set `job` to the job in the upstream pipeline to fetch artifacts from,
   `ref` to the branch, and `artifacts: true`.

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - project: my/upstream_project
         job: build_artifacts
         ref: main
         artifacts: true
   ```

#### Pass artifacts to a downstream pipeline from a Merge Request pipeline

When you use `needs:project` to [pass artifacts to a downstream pipeline](#pass-artifacts-to-a-downstream-pipeline),
the `ref` value is usually a branch name, like `main` or `development`.

For merge request pipelines, the `ref` value is in the form of `refs/merge-requests/<id>/head`,
where `id` is the merge request ID. You can retrieve this ref with the [`CI_MERGE_REQUEST_REF_PATH`](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines)
CI/CD variable. Do not use a branch name as the `ref` with merge request pipelines,
because the downstream pipeline attempts to fetch artifacts from the latest branch pipeline.

To fetch the artifacts from the upstream `merge request` pipeline instead of the `branch` pipeline,
pass this variable to the downstream pipeline using variable inheritance:

1. In a job in the upstream pipeline, save the artifacts using the [`artifacts`](../yaml/index.md#artifacts) keyword.
1. In the job that triggers the downstream pipeline, pass the `$CI_MERGE_REQUEST_REF_PATH` variable by using
   [variable inheritance](downstream_pipelines.md#pass-yaml-defined-cicd-variables):

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   upstream_job:
     variables:
       UPSTREAM_REF: $CI_MERGE_REQUEST_REF_PATH
     trigger:
       project: my/downstream_project
       branch: my-branch
   ```

1. In a job in the downstream pipeline, fetch the artifacts from the upstream pipeline
   by using `needs:project`. Set the `ref` to the `UPSTREAM_REF` variable, and `job`
   to the job in the upstream pipeline to fetch artifacts from:

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - project: my/upstream_project
         job: build_artifacts
         ref: UPSTREAM_REF
         artifacts: true
   ```

This method works for fetching artifacts from a regular merge request parent pipeline,
but fetching artifacts from [merge results](merged_results_pipelines.md) pipelines is not supported.

#### Use `rules` or `only`/`except` with multi-project pipelines

You can use CI/CD variables or the [`rules`](../yaml/index.md#rulesif) keyword to
[control job behavior](../jobs/job_control.md) for multi-project pipelines. When a
downstream pipeline is triggered with the [`trigger`](../yaml/index.md#trigger) keyword,
the value of the [`$CI_PIPELINE_SOURCE` predefined variable](../variables/predefined_variables.md)
is `pipeline` for all its jobs.

If you use [`only/except`](../yaml/index.md#only--except) to control job behavior, use the
[`pipelines`](../yaml/index.md#onlyrefs--exceptrefs) keyword.

### Create multi-project pipelines by using the API

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/31573) to GitLab Free in 12.4.

When you use the [`CI_JOB_TOKEN` to trigger pipelines](../jobs/ci_job_token.md),
GitLab recognizes the source of the job token. The pipelines become related,
so you can visualize their relationships on pipeline graphs.

These relationships are displayed in the pipeline graph by showing inbound and
outbound connections for upstream and downstream pipeline dependencies.

When using:

- CI/CD variables or [`rules`](../yaml/index.md#rulesif) to control job behavior, the value of
  the [`$CI_PIPELINE_SOURCE` predefined variable](../variables/predefined_variables.md) is
  `pipeline` for multi-project pipeline triggered through the API with `CI_JOB_TOKEN`.
- [`only/except`](../yaml/index.md#only--except) to control job behavior, use the
  `pipelines` keyword.

## Multi-project pipeline visualization **(PREMIUM)**

When your pipeline triggers a downstream pipeline, the downstream pipeline displays
to the right of the [pipeline graph](index.md#visualize-pipelines).

![Multi-project pipeline graph](img/multi_project_pipeline_graph_v14_3.png)

In [pipeline mini graphs](index.md#pipeline-mini-graphs), the downstream pipeline
displays to the right of the mini graph.

![Multi-project pipeline mini graph](img/pipeline_mini_graph_v15_0.png)
