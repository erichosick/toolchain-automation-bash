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

# Create a new branch for CommitLint setup
git checkout -b @setup/commitlint

# Set branch title
export BRANCH_TITLE="lint commit messages"

# Create a GitHub issue for setting up CommitLint
export ISSUE_NUMBER=$(gh issue create --title "setup $BRANCH_TITLE" \
  --body "Use commitlint to lint commit messages" \
  --label "enhancement" \
  --assignee "$GITHUB_ASSIGNEE" | awk -F '/' '{print $NF}')

# Install CommitLint and set up configurations
pnpm install --save-dev @commitlint/{config-conventional,cli}
pnpm pkg set scripts.commitlint="npx commitlint --config=.config/commitlint.config.mjs --strict --verbose"

# Create .config directory and CommitLint config file
mkdir -p .config
echo "const commitlintConfg = {
  extends: ['@commitlint/config-conventional']
};

export default commitlintConfg;" > .config/commitlint.config.mjs

# Set up Husky to use CommitLint for commit message validation
pnpm husky add .config/husky/commit-msg "#validate the commit message
pnpm commitlint --edit \$1"

# Commit the changes
git add .
git commit -m "feat(setup): commit message linting with commitlint

Use commitlint to lint commit messages
  * create .config directory
  * add [commitlint](https://github.com/conventional-changelog/commitlint)
  * create commit lint config
  * add commitlint to package.json script
  * config husky to call commitlint

issue: #$ISSUE_NUMBER
"

# Merge changes into the main branch and delete the setup branch
git checkout main
git merge @setup/commitlint
git branch -d @setup/commitlint

# Push changes to GitHub
git push origin main
git tag step_0070_commitlint -m "$BRANCH_TITLE"

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
