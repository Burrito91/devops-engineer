# Troubleshooting Runbook - Burrito DevOps Pipeline

## Failure 1: Test job fails
* **Symptom:** Job 1 (test) shows red in Actions.
* **Causes:**
  * A unit test is failing.
  * Lint errors in the code.
  * `npm ci` fails because `package-lock.json` is out of sync.
* **Fix:**
  1. Click the failed job in GitHub Actions -> expand the failed step -> read the error output.
  2. Reproduce locally: run `npm test` or `npm run lint`.
  3. Fix the code, then `git push` — the pipeline will retry automatically.
  4. If `npm ci` fails: delete `node_modules`, run `npm install`, and commit the updated `package-lock.json`.

---

## Failure 2: Trivy blocks the pipeline
* **Symptom:** Job 2 (build) fails with "CRITICAL vulnerability found".
* **Causes:**
  * A base image or npm dependency contains a known CVE with a patch available.
* **Fix:**
  1. Read the Trivy output — it names the package, CVE ID, and the fixed version.
  2. Update the base image: change `FROM node:20-alpine` to `FROM node:22-alpine` (or appropriate patch version).
  3. Or update the npm package: `npm update <PACKAGE-NAME>`.
  4. Rebuild and push — if Trivy still fails, check for fixes at [nvd.nist.gov](https://nvd.nist.gov).
  5. If no fix exists yet, add an exception to `.trivyignore`:
     `CVE-2024-XXXXX # no fix available as of YYYY-MM-DD`
  * **DO NOT:** Set `exit-code: "0"` to silence the security scan. Always fix or document the vulnerability.

---

## Failure 3: ECS service hangs during deploy
* **Symptom:** Job 3 (deploy) runs for 10+ minutes then fails with "service did not reach a steady state".
* **Causes:**
  * New tasks start but fail application health checks.
  * Container crashes immediately upon startup.
  * Wrong port mapping configured in the task definition.
* **Fix:**
  1. Navigate to AWS ECS -> `burrito-devops-engineer-cluster` -> `myapp-service` -> **Tasks** tab.
  2. Find a task with status `STOPPED` -> click it -> read the **Stopped reason**.
  3. Go to CloudWatch -> `/ecs/myapp` -> find the log stream for the failing task.
  4. Read the last 20 log lines to find the crash traceback.
  * **Common causes & resolutions:**
    * *CannotPullContainerError:* ECR URI is incorrect, or the ECS execution role lacks ECR read permissions.
    * *App crashes:* Missing environment variables — add them to the task definition.
    * *Health check fails:* Wrong port configured in the target group, or the health endpoint returns a non-200 status code.
  * **Emergency Rollback (while investigating):**
    * Go to ECS -> `myapp-service` -> **Update service**.
    * Task definition: select the previous stable revision number.
    * Check **Force new deployment** -> Click **Update**.

---

## Failure 4: OIDC authentication fails
* **Symptom:** `"Error: Could not assume role"` error message during Job 2 or Job 3.
* **Cause:**
  * The IAM role trust policy condition does not match your GitHub repository path.
* **Fix:**
  1. Go to AWS IAM -> **Roles** -> `github-actions-deploy-role` -> **Trust relationships** tab.
  2. Inspect the Condition block:
     `"token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:*"`
  3. Verify that `OWNER` and `REPO` explicitly match your exact GitHub username and repository name (`burrito-devops-engineer`), keeping case sensitivity in mind.
  4. Update the policy, save changes, and re-run the pipeline.
