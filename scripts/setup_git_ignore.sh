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

# Create a new branch for .gitignore setup
git checkout -b @setup/gitignore

# Set branch title
export BRANCH_TITLE=".gitignore file"

# Create a GitHub issue for adding the .gitignore file
export ISSUE_NUMBER=$(gh issue create --title "setup $BRANCH_TITLE" \
  --body "Add $BRANCH_TITLE to $PROJECT_NAME" \
  --label "enhancement" \
  --assignee "$GITHUB_ASSIGNEE" | awk -F '/' '{print $NF}')

# Create .gitignore file with initial content
echo "
# NOTE: Git implies **/ for each listed name, ignoring them recursively by
# default. To ignore a specific item, pre-pend its path relative to the
# repository root.

# mac OS files
.DS_Store

# node temporary files
node_modules

# pnpm-specific temporary files
.pnpm/
.pnpm-debug.log*" > .gitignore

# Commit the .gitignore file
git add .gitignore
git commit -m "feat(setup): create gitignore file with focus on node, pnpm and mac OS

Minimal .gitignore file for node development on macos
  * add .gitignore file

issue: #$ISSUE_NUMBER
"

# Merge changes into the main branch and delete the setup branch
git checkout main
git merge @setup/gitignore
git branch -d @setup/gitignore

# Push changes to GitHub
git push origin main
git tag step_0040_git_ignore -m "setup $BRANCH_TITLE"

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
