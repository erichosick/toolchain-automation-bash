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

# Create a new branch for ESLint watch setup
git checkout -b @setup/eslint-watch

# Set branch title
export BRANCH_TITLE="watch eslint changes"

# Create a GitHub issue for setting up ESLint watch
export ISSUE_NUMBER=$(gh issue create --title "setup $BRANCH_TITLE" \
  --body "Continually run eslint: aka watch" \
  --label "enhancement" \
  --assignee "$GITHUB_ASSIGNEE" | awk -F '/' '{print $NF}')

# Install Nodemon and set up configurations
pnpm add --save-dev nodemon
mkdir -p .config
echo "
{
  \"verbose\": true,
  \"ignore\": [],
  \"delay\": 200,
  \"ext\": \"\",
  \"watch\": \"*.*\",
  \"rule\": \"**.*/*\"
}

" > .config/nodemon.config.json

pnpm pkg set 'scripts.eslint:watch'="nodemon --exec 'ESLINT_USE_FLAT_CONFIG=true npx eslint --config eslint.config.mjs .' --config .config/nodemon.config.json"

# Commit the changes
git add .
git commit -m "feat(setup): watch eslint with nodemon

Automatically run eslint when files change.
  * add nodemon as a dependency
  * add package.json script to run eslint in watch mode
  * provide default configuration to monitor all files

issue: #$ISSUE_NUMBER
"

# Merge changes into the main branch and delete the setup branch
git checkout main
git merge @setup/eslint-watch
git branch -d @setup/eslint-watch

# Push changes to GitHub
git push origin main
git tag step_0102_eslint_watch -m "$BRANCH_TITLE"

# Close GitHub issue
gh issue close $ISSUE_NUMBER \
  --reason completed \
  --comment "fixed by: [#$(git rev-parse --short HEAD)](https://github.com/$GITHUB_ORG_NAME/$PROJECT_NAME/commit/$(git rev-parse HEAD))"

# Unset environment variables
unset ISSUE_NUMBER
unset BRANCH_TITLE

# Generate a new version and push tags
pnpm release
