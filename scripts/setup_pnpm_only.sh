#!/bin/zsh

# Source utilities script
source ./tools/env_var_operations.sh

# Check required environment variables
environment_variable_verify "PROJECT_DIR" || return $?
environment_variable_verify "PROJECT_NAME" || return $?
environment_variable_verify "GITHUB_ORG_NAME" || return $?
environment_variable_verify "GITHUB_ASSIGNEE" || return $?

# Change to the project directory
cd "$PROJECT_DIR" || { echo "Error: Failed to change into directory '$PROJECT_DIR'"; exit 1; }

# Create a new branch for pnpm-only setup
git checkout -b @setup/pnpm-only

# Set branch title
export BRANCH_TITLE="enforce pnpm usage"

# Create a GitHub issue for enforcing pnpm usage
export ISSUE_NUMBER=$(gh issue create --title "setup $BRANCH_TITLE" \
  --body "Enforce pnpm usage" \
  --label "enhancement" \
  --assignee "$GITHUB_ASSIGNEE" | awk -F '/' '{print $NF}')

# Execute the curl command to run the setup script
curl -sL https://raw.githubusercontent.com/erichosick/pnpm-only-template/main/pnpm-only.sh | bash

# Commit the changes
git add .
git commit -m "feat(setup): enforce pnpm usage

Assure only pnpm is used in the project for installing node packages.
  * use [only-allow](https://github.com/pnpm/only-allow)
  * add preinstall script
  * add .npmrc that assures version is enforced
  * version of npm is set as a note for developer to only use pnpm

issue: #$ISSUE_NUMBER
"

# Merge changes into the main branch and delete the setup branch
git checkout main
git merge @setup/pnpm-only
git branch -d @setup/pnpm-only

# Push changes to GitHub
git push origin main
git tag step_0050_pnpm_only -m "$BRANCH_TITLE"

# Close GitHub issue
gh issue close $ISSUE_NUMBER \
  --reason completed \
  --comment "fixed by: [#$(git rev-parse --short HEAD)](https://github.com/$GITHUB_ORG_NAME/$PROJECT_NAME/commit/$(git rev-parse HEAD))"

# Unset environment variables
unset ISSUE_NUMBER
unset BRANCH_TITLE

# Generate a new version and push tags
npx standard-version
git push --follow-tags origin main
