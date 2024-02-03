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

# Create a new branch for standard-version setup
git checkout -b @setup/standard-version

# Set branch title
export BRANCH_TITLE="changesets and versions"

# Create a GitHub issue for setting up standard-version
export ISSUE_NUMBER=$(gh issue create --title "setup $BRANCH_TITLE" \
  --body "Use standard-version to manage changesets and versions" \
  --label "enhancement" \
  --assignee "$GITHUB_ASSIGNEE" | awk -F '/' '{print $NF}')

# Install standard-version and set up configurations
pnpm install --save-dev standard-version
pnpm pkg set scripts.release="standard-version && git push --follow-tags origin main"

# Commit the changes
git add .
git commit -m "feat(setup): standard version

Use standard-version to generate changesets and increment versions based on commit messages
  * add [standard-version](https://github.com/conventional-changelog/standard-version)
  * add release script

issue: #$ISSUE_NUMBER
"

# Merge changes into the main branch and delete the setup branch
git checkout main
git merge @setup/standard-version
git branch -d @setup/standard-version

# Push changes to GitHub
git push origin main
git tag step_0080_standard_version -m "$BRANCH_TITLE"

# Close GitHub issue
gh issue close $ISSUE_NUMBER \
  --reason completed \
  --comment "fixed by: [#$(git rev-parse --short HEAD)](https://github.com/$GITHUB_ORG_NAME/$PROJECT_NAME/commit/$(git rev-parse HEAD))"

# Unset environment variables
unset ISSUE_NUMBER
unset BRANCH_TITLE

# Release the new version
pnpm release
