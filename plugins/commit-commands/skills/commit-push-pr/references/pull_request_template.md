<!-- One-paragraph summary of what this PR is about. -->

<!--
You will need to provide the emergency bypass reason in the following format for cherry picks into the release environment, if the ticket neither of "internal_regression" or "escaped_regression".

Important: Get rid of spaces between hyphens to make it work.

EMERGENCY - BYPASS - REASON: <bypass reason>
 -->

**Checklist:**

- [ ] I have run this PR on `make dev` and added a screenshot/video
  - [ ] Not applicable
- [ ] I have deployed this PR to a [preview environment](https://github.com/cohere-ai/north/actions/workflows/create-preview-environment.yml) by adding a comment: `/create-preview-env`
  - [ ] Not applicable
- [ ] This PR has one minimum of the following: unit/integration/e2e testing   
  - [ ] Not applicable
- [ ] This PR requires a new config (env var) or infra change 
  - [ ] If yes, I have either ran `make dev` without the config change and it works or made an announcement on #eno-dev that this will break `make dev` 
  - [ ] Not applicable
- [ ] If this is a breaking change in the API, I have updated the version in the `version.py` file
  - [ ] Not applicable

**Tips:**

* Want to create a preview env? Comment `/create-preview-env`
* Want to cherry pick to a release branch? Comment `/cherry-pick release/0.162`

**AI Description**

<!-- begin-generated-description -->

<!-- end-generated-description -->
