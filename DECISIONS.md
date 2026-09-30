# Architectural Decision Records (ADRs) - Burrito DevOps Pipeline

## Decision 1: OIDC instead of AWS access keys
* **What we chose:** `aws-actions/configure-aws-credentials` with `role-to-assume`.
* **What the alternative was:** Storing `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as GitHub repository secrets.
* **Why we chose this:** Access keys are long-lived credentials — if the repository is compromised, an attacker has permanent access to your AWS account. An OIDC token is dynamically requested from AWS STS, valid only for the duration of a single pipeline run, and expires immediately afterward.
* **Trade-off:** Requires a one-time setup of an IAM OIDC identity provider and trust policy role in AWS.

## Decision 2: Tag images with git SHA, not :latest
* **What we chose:** Tagging images as `myapp:$SHA` (using the 7-character commit hash).
* **What the alternative was:** Pushing and deploying using `myapp:latest` on every build.
* **Why we chose this:** The `:latest` tag is ambiguous; it provides no traceability to the exact code version running in production. Using the Git SHA allows you to run `git show abc1234` to pinpoint the exact commit, which is crucial for rollbacks and debugging incidents.
* **Trade-off:** Amazon ECR accumulates images over time, requiring a lifecycle policy to purge images older than 30 days.

## Decision 3: Block pipeline on CRITICAL Trivy findings
* **What we chose:** Setting `exit-code: "1"` on the Trivy container vulnerability scan step.
* **What the alternative was:** Scanning without failing (`exit-code: "0"`) or skipping vulnerability scans entirely.
* **Why we chose this:** Allowing a vulnerable image to reach ECR risks deploying vulnerabilities straight to production. Failing the build blocks compromised artifacts instantly.
* **Trade-off:** Critical CVEs in base packages or third-party dependencies can block emergency deployments until patched (mitigated via `--ignore-unfixed` where needed).

## Decision 4: Automated Blue/Green Canary Rollout with ALB and CodeDeploy
* **What we chose:** Executing automated traffic shifting via an Application Load Balancer (`burrito-alb`) with a canary pattern (shifting 10% traffic, waiting 5 minutes for monitoring validation, then promoting to 100%).
* **What the alternative was:** Immediate all-at-once rolling updates or manual target group switching.
* **Why we chose this:** Minimizes production downtime and user disruption by safely validating the new task set (`burrito-tg-green`) against live traffic before cutting over entirely from the blue environment (`burrito-tg-blue`).
* **Trade-off:** Adds configuration complexity across multiple target groups, test/prod listeners, and ECS task set definitions.
