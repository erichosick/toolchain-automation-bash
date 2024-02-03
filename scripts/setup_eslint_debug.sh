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

# Create a new branch for ESLint debug setup
git checkout -b @setup/eslint-debug

# Set branch title
export BRANCH_TITLE="debug eslint in vscode"

# Create a GitHub issue for setting up ESLint debug
export ISSUE_NUMBER=$(gh issue create --title "setup $BRANCH_TITLE" \
  --body "Debug eslint in visual studio code" \
  --label "enhancement" \
  --assignee "$GITHUB_ASSIGNEE" | awk -F '/' '{print $NF}')

# Create .vscode/launch.json if it doesn't exist
[ ! -f .vscode/launch.json ] && mkdir -p .vscode && echo "{}" > .vscode/launch.json

# Add comments, version, and configurations to launch.json
jq '
{
  "_comment01": "Use IntelliSense to learn about possible attributes.",
  "_comment02": "Hover to view descriptions of existing attributes.",
  "_comment03": "For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387",
  "version": "0.2.0"
} + if .configurations == null then .configurations = [] else . end' .vscode/launch.json > temp.json && mv temp.json .vscode/launch.json

# Add or overwrite the Debug ESLint Configuration in launch.json
jq '(.configurations |= map(select(.name != "Debug ESlint Configuration")) ) | .configurations += [{
      "type": "node",
      "request": "launch",
      "name": "Debug ESlint Configuration",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["run-script", "eslint"],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen",
      "env": {
        "NODE_ENV": "test",
        "NODE_OPTIONS": "--experimental-vm-modules"
      },
    }]' .vscode/launch.json > temp.json && mv temp.json .vscode/launch.json

# Commit the changes
git add .
git commit -m "feat(setup): $BRANCH_TITLE

Enable debugging of eslint in visual studio code.
  * create .vscode/launch.json if one does not exist
  * add comments + configuration array
  * add or overwrite Debug ESlint Configuration

issue: #$ISSUE_NUMBER
"

# Merge changes into the main branch and delete the setup branch
git checkout main
git merge @setup/eslint-debug
git branch -d @setup/eslint-debug

# Push changes to GitHub
git push origin main
git tag step_0104_eslint_debug -m "$BRANCH_TITLE"

# Close GitHub issue
gh issue close $ISSUE_NUMBER \
  --reason completed \
  --comment "fixed by: [#$(git rev-parse --short HEAD)](https://github.com/$GITHUB_ORG_NAME/$PROJECT_NAME/commit/$(git rev-parse HEAD))"

# Unset environment variables
unset ISSUE_NUMBER
unset BRANCH_TITLE

# Generate a new version and push tags
pnpm release
