#!/bin/zsh

# Source utilities script
source ./tools/env_var_operations.sh
source ./tools/markdown.sh

# Check required environment variables
environment_variable_verify "PROJECT_DIR" || return $?
environment_variable_verify "PROJECT_NAME" || return $?
environment_variable_verify "REPOSITORY_NAME" || return $?
environment_variable_verify "GITHUB_ORG_NAME" || return $?
environment_variable_verify "GITHUB_ASSIGNEE" || return $?
environment_variable_verify "PROJECT_LICENSE" || return $?
environment_variable_verify "PROJECT_DESCRIPTION" || return $?
environment_variable_verify "AUTHOR_NAME" || return $?
environment_variable_verify "AUTHOR_EMAIL" || return $?
environment_variable_verify "AUTHOR_URL" || return $?
environment_variable_verify "PROJECT_KEYWORDS" || return $?
environment_variable_verify "README_ADDITIONAL" || return $?

# Change to the project directory
cd "$PROJECT_DIR" || { echo "Error: Failed to change into directory '$PROJECT_DIR'"; exit 1; }

# Create a new branch for Node.js project setup
git checkout -b @setup/node-project

# Set branch title
export BRANCH_TITLE="package.json and readme.md"

# Create a GitHub issue for setting up the Node.js project
export ISSUE_NUMBER=$(gh issue create --title "setup $BRANCH_TITLE" \
  --body "Setup $BRANCH_TITLE in $REPOSITORY_NAME" \
  --label "enhancement" \
  --assignee "$GITHUB_ASSIGNEE" | awk -F '/' '{print $NF}')

# Generate package.json
echo '{
  "name": "'"$PROJECT_NAME"'",
  "version": "1.0.0",
  "license": "'"$PROJECT_LICENSE"'",
  "private": true,
  "description": "'"$PROJECT_DESCRIPTION"'",
  "keywords": [],
  "homepage": "https://github.com/'"$GITHUB_ORG_NAME"'/'"$REPOSITORY_NAME"'#readme",
  "bugs": {
    "url": "https://github.com/'"$GITHUB_ORG_NAME"'/'"$REPOSITORY_NAME"'/issues",
    "email": "'"$AUTHOR_EMAIL"'"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/'"$GITHUB_ORG_NAME"'/'"$REPOSITORY_NAME"'.git"
  },
  "author": {
    "name": "'"$AUTHOR_NAME"'",
    "email": "'"$AUTHOR_EMAIL"'",
    "url": "'"$AUTHOR_URL"'"
  },
  "contributors": [],
  "engines": {
    "node": "^18.18.0 || ^20.9.0 || >=21.1.0"
  },
  "scripts": {}
}' > package.json

# Update package.json with keywords
jq --argjson keywords "$(echo $PROJECT_KEYWORDS | jq -R 'split(",")')" '.keywords = $keywords' package.json > package.json.tmp && mv package.json.tmp package.json

# Create README.md
echo "# $REPOSITORY_NAME"$'\n\n'"$PROJECT_DESCRIPTION" > README.md
echo "$README_ADDITIONAL" >> README.md

# Commit changes
git add .
git commit -m "feat(setup): $BRANCH_TITLE

Setup package.json
  - run script to generate package.json

Setup readme.md
  - run script to generate readme.md

issue: #$ISSUE_NUMBER
"

# Merge changes into main branch and delete setup branch
git checkout main
git merge @setup/node-project
git branch -d @setup/node-project

# Push changes to GitHub
git push origin main
git tag step_0020_node -m "setup $BRANCH_TITLE"

# Close GitHub issue
gh issue close $ISSUE_NUMBER \
  --reason completed \
  --comment "fixed by: [#$(git rev-parse --short HEAD)](https://github.com/$GITHUB_ORG_NAME/$REPOSITORY_NAME/commit/$(git rev-parse HEAD))"

# Unset environment variables
unset ISSUE_NUMBER
unset BRANCH_TITLE

# Generate a new version and push tags
npx standard-version
git push --follow-tags origin main
