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

# Create a new branch for Husky setup
git checkout -b @setup/husky

# Set branch title
export BRANCH_TITLE="git hooks with husky"

# Create a GitHub issue for setting up Husky
export ISSUE_NUMBER=$(gh issue create --title "setup $BRANCH_TITLE" \
  --body "Setup $BRANCH_TITLE" \
  --label "enhancement" \
  --assignee "$GITHUB_ASSIGNEE" | awk -F '/' '{print $NF}')

# Create .config directory and install Husky
mkdir -p .config
pnpm install --save-dev husky

# Set Husky configuration in package.json
pnpm pkg set scripts.postinstall="husky install .config/husky"
pnpm pkg set scripts.prepare="husky install .config/husky"

# Prepare Husky
pnpm prepare

# Commit the changes
git add .
git commit -m "feat(setup): git hooks with husky

Husky is used to manage git hooks.
  * use [husky](https://github.com/typicode/husky)
  * config file located in .config directory
  * create postinstall script
  * create prepare script
  * add example pre-commit hook

issue: #$ISSUE_NUMBER
"

# Merge changes into the main branch and delete the setup branch
git checkout main
git merge @setup/husky
git branch -d @setup/husky

# Push changes to GitHub
git push origin main
git tag step_0060_git_hooks_husky -m "$BRANCH_TITLE"

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
