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

# Create a new branch for ESLint flat config setup
git checkout -b @setup/eslint-flat-config

# Set branch title
export BRANCH_TITLE="eslint with flat config"

# Create a GitHub issue for setting up ESLint flat config
export ISSUE_NUMBER=$(gh issue create --title "setup $BRANCH_TITLE" \
  --body "Setup eslint flat config." \
  --label "enhancement" \
  --assignee "$GITHUB_ASSIGNEE" | awk -F '/' '{print $NF}')

# Create directories for ESLint configuration
mkdir -p .config
mkdir -p .config/eslint

# Install ESLint and set up the script
pnpm add --save-dev eslint@9
pnpm pkg set 'scripts.eslint'="npx eslint --config eslint.config.mjs ."

# Create global configuration object file
echo "/**
 * @type import('eslint').Linter.Config[]
 * Global configuration object for eslint. Rules in this object are applied
 * to all files.
 */
const globalConfigObjects = [
  {
    ignores: ['**/dist'],
  },
];

export default globalConfigObjects;" > .config/eslint/global-config-objects.mjs

# Create ESLint configuration file
echo "import globalConfigObjects from './.config/eslint/global-config-objects.mjs';

const eslintConfigObjects = [
  ...globalConfigObjects,
];

export default eslintConfigObjects;" > eslint.config.mjs

# Set up Husky to use ESLint for commit message validation
pnpm husky add .config/husky/commit-msg "
#validate the files that have changed using eslint
pnpm eslint "

# Commit the changes
git add .
git commit -m "feat(setup): use eslint + flat config to lint files in visual studio code

Setup eslint along with flat config.
  * create the .config/eslint directory to place files with configuration objects.
  * add global configuration object
  * add eslint.config.mjs file
  * have eslint run before commit

issue: #$ISSUE_NUMBER
"

# Merge changes into the main branch and delete the setup branch
git checkout main
git merge @setup/eslint-flat-config
git branch -d @setup/eslint-flat-config

# Push changes to GitHub
git push origin main
git tag step_0100_eslint_json -m "$BRANCH_TITLE"

# Close GitHub issue
gh issue close $ISSUE_NUMBER \
  --reason completed \
  --comment "fixed by: [#$(git rev-parse --short HEAD)](https://github.com/$GITHUB_ORG_NAME/$PROJECT_NAME/commit/$(git rev-parse HEAD))"

# Unset environment variables
unset ISSUE_NUMBER
unset BRANCH_TITLE

# Generate a new version and push tags
pnpm release
