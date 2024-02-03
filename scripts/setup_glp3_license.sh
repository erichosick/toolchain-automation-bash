#!/bin/zsh

# Source utilities script
source ./tools/env_var_operations.sh

# Check required environment variables
environment_variable_verify "PROJECT_DIR" || return $?
environment_variable_verify "PROJECT_NAME" || return $?
environment_variable_verify "GITHUB_ORG_NAME" || return $?
environment_variable_verify "GITHUB_ASSIGNEE" || return $?
environment_variable_verify "PROJECT_LICENSE" || return $?

# Change to the project directory
cd "$PROJECT_DIR" || { echo "Error: Failed to change into directory '$PROJECT_DIR'"; exit 1; }

# Create a new branch for updating the license
git checkout -b @chore/license

# Set branch title
export BRANCH_TITLE="license.txt file"

# Create a GitHub issue for adding the license
export ISSUE_NUMBER=$(gh issue create --title "setup $BRANCH_TITLE" \
  --body "Add $BRANCH_TITLE to $PROJECT_NAME" \
  --label "enhancement" \
  --assignee "$GITHUB_ASSIGNEE" | awk -F '/' '{print $NF}')

# Update the license in package.json
jq --arg license "$PROJECT_LICENSE" '.license = $license' package.json > temp.json && mv temp.json package.json

# Download the GPL license text
curl https://www.gnu.org/licenses/gpl-3.0.txt -o LICENSE.txt

# Update README.md with license information
echo "
# Software License

This software is licensed under the GNU General Public License v3.0 or later (GPL-3.0-or-later). For more details, see [LICENSE.txt](./LICENSE.txt) or the [GNU General Public License v3.0 page](https://www.gnu.org/licenses/gpl-3.0-standalone.html).

Since this is a workspace, other packages within it may be licensed under different terms. In such cases, the package will contain its own licensing terms." >> README.md

# Commit changes
git add .
git commit -m "feat(setup): $BRANCH_TITLE

Adds gpl-3-0-or-later license with the intent to dual license at some point.
  * update package.json to have correct license
  * copy license text from www.gnu.org/licenses/gpl-3.0.txt
  * update readme.md

issue: #$ISSUE_NUMBER
"

# Merge changes into main branch and delete setup branch
git checkout main
git merge @chore/license
git branch -d @chore/license

# Push changes to GitHub
git push origin main
git tag step_0030_license -m "add $BRANCH_TITLE"

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
