#!/bin/bash
# @name git_operations
# @brief Idempotent git operations
# @description
# A collection of useful git operations

# @description Verify the current directory is a git project
# @example
#   is_git_repository
#
# @exitcode 0 : The directory is a git project
# @exitcode 1 : The directory is not a git project
is_git_repository() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "is_git_repository" "Usage is_git_repository <project_directory>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"

  local git_rev_output
  git_rev_output=$(execute_call_in "$project_directory" git rev-parse --is-inside-work-tree)
  local git_rev_status=$?

  # if we aren't in a git repository, then git rev-parse will return an error
  # fatal: not a git repository (or any of the parent directories): .git
  # otherwise, it seems to return a literal true
  if [ "$git_rev_output" = "true" ]; then
    return 0
  else
    return 1
  fi
}

# @description Check if we are currently on the branch provided in
# <branch_name>.
# @example
#   on_branch <project_directory> <branch_name>
#
# @arg $1 Project directory.
# @arg $2 Branch name.
#
# @exitcode 0 : We are on the branch provided.
# @exitcode 1 : If there was an error making the call
# @exitcode 2 : We are not on the branch provided.
on_branch() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "on_branch" "Usage on_branch <project_directory> <branch_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local branch_name="$2"

  local git_status_output
  git_status_output=$(execute_call_in "$project_directory" git status)
  local git_status_status=$?


  if [ "$git_status_status" -ne 0 ]; then
    if [ "fatal: not a git repository (or any of the parent directories): .git" = "$git_status_output" ]; then
      # this might be expected if the git repository doesn't exist yet and
      # we are checking if a tag exists
      return 0
    else
      print_status "error" "on_branch" "Failed to get git status. Message: $git_status_output"
      return $git_status_status
    fi
  fi

  if [[ "$git_status_output" =~ "On branch $branch_name" ]]; then
    return 0
  else
    return 2
  fi
}



# @description Check if the branch name provided is already in the current
# repository.
# @example
#   has_branch <project_directory> <branch_name>
#
# @arg $1 Project directory.
# @arg $2 Branch name.
#
# @exitcode 0 : The branch exists
# @exitcode 1 : The branch does not exist
has_branch() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "is_git_repository" "Usage is_git_repository <project_directory> <branch_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local branch_name="$2"

  local git_branch_list_output
  git_branch_list_output=$(execute_call_in "$project_directory" git branch --list "$branch_name")
  local git_branch_list_status=$?

  if [ "$git_branch_list_status" -ne 0 ]; then
    if [ "fatal: not a git repository (or any of the parent directories): .git" = "$git_branch_list_output" ]; then
      # this might be expected if the git repository doesn't exist yet and
      # we are checking if a tag exists
      return 0
    else
      print_status "error" "has_branch" "Failed to list tags. Message: $git_branch_list_output"
      return $git_branch_list_status
    fi
  fi

  local branch_match
  branch_match=$(echo "$git_branch_list_output" | grep -E "^  $branch_name$")
  if [ -n "$branch_match" ]; then
    return 0
  else
    return 1
  fi
}

# @description Check if a git tag exists. Returns 0 if the tag does not and
# 1 if the tag exists. If the git repository does not exist, then that is
# considered as the tag not existing.
# @example
#   git_tag_not_exists <project_directory> <tag_name>
#
# @arg $1 Project directory.
# @arg $2 Tag name.
#
# @exitcode 0 : The tag does not exist
# @exitcode 1 : If there is an error
# @exitcode 2 : The tag exists
git_tag_not_exists() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "git_tag_not_exists" "Usage git_tag_not_exists <project_directory> <tag_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local tag_name="$2"
  

  local git_tag_list_output
  git_tag_list_output=$(execute_call_in "$project_directory" git tag -l "$tag_name")
  local git_tag_list_status=$?

  if [ "$git_tag_list_status" -ne 0 ]; then
    if [ "fatal: not a git repository (or any of the parent directories): .git" = "$git_tag_list_output" ]; then
      # this might be expected if the git repository doesn't exist yet and
      # we are checking if a tag exists
      return 0
    else
      print_status "error" "git_tag_not_exists" "Failed to list tags. Message: $git_tag_list_output"
      return $git_tag_list_status
    fi
  fi

  if [ "$git_tag_list_output" = "$tag_name" ]; then
    return 2
  else
    return 0
  fi
}

# @description Check if a feature exists
# @example
#   feature_exists <project_directory> <feature_name>
#
# @arg $1 Project directory.
# @arg $2 Feature name.
#
# @exitcode 0 : The feature does not exist
# @exitcode 1 : The feature exists
feature_exists() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "feature_exists" "Usage feature_exists <project_directory> <feature_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local feature_name="$2"

  git_tag_not_exists "$project_directory" "$feature_name"
  local git_tag_not_exists_status=$?

  if [ $git_tag_not_exists_status -eq 0 ]; then
    return 0
  elif [ $git_tag_not_exists_status -eq 2 ]; then
    return 1
  else
    print_status "error" "feature_exists" "Failed to check if feature '$feature_name' exists"
    return $git_tag_not_exists_status
  fi
}


feature_exists_status() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "feature_exists" "Usage feature_exists_status <project_directory> <feature_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local feature_name="$2"

  feature_exists "$project_directory" "$feature_name"
  local feature_exists_status=$?

  if [ $feature_exists_status -eq 1 ]; then
    print_status "skipped" "feature_exists_status" "Feature '$feature_name' exists"
  fi
  return $feature_exists_status

}

# @description The intent of this function is to check if a feature has already
# been committed to the repository. A feature exits if a commit message exists
# with the feature name in the commit message (feature: $feature_name). If
# this is ran outside of a git repo, then we assume the feature does not exist.
# The idea being that a script responsible for creating the git repo would
# check if the feature exists.
# @example
#   git_commit_exists "feature_0010_main_branch"
#
# @exitcode 0 : The feature does not exist so move forward with feature setup.
# @exitcode 1 : The features exists so skip setup.
feature_commit_exists() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "feature_commit_exists" "Usage feature_commit_exists <project_directory> <feature_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local feature_name="$2"

  local git_log_output
  git_log_output=$(execute_call_in "$project_directory" git log --grep="feature: $feature_name" --oneline)
  local git_log_status=$?

  if [ $git_log_status -ne 0 ]; then
    # case where fatal: your current branch 'staging' does not have any commits yet
    # so the feature does not exist yet
    return 0
  else
    if [ -z "$git_log_output" ]; then
      return 0
    else
      return 1
    fi
  fi
}

git_add() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "git_add" "Usage git_add <project_directory> <branch_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local branch_name="$2"

  git_checkout "$project_directory" "$branch_name" || return $?
  local git_checkout_status=$?

  if [ $git_checkout_status -ne 0 ]; then
    print_status "error" "git_add" "Failed to checkout branch '$branch_name'"
    return $git_checkout_status
  fi

  local git_add_output
  git_add_output=$(execute_call_in "$project_directory" git add . --verbose)
  local git_add_status=$?

  if [ $git_add_status -ne 0 ]; then
    print_status "error" "git_add" "Failed to add files to the $branch_name branch. Message: $git_add_output"
    return $git_add_status
  else
    if [ -z "$git_add_output" ]; then
      print_status "skipped" "git_add" "All files already added to the $branch_name branch"
    else
      print_status "success" "git_add" "Add changes to $branch_name branch"
    fi

    return 0
  fi
}

# @description Initialize a git repository
# @example
#   git_init <project_directory>
#
# @arg $1 Project directory.
#
# @exitcode 0  If the git repository was initialized successfully.
# @exitcode 1  If any error occurred.
git_init() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "git_init" "Usage git_init <project_directory>. Values(s) passed were '$#'"
    return 1
  fi

  if is_git_repository "$project_directory"; then
    print_status "skipped" "git_init" "Local Git repository exists"
    return 0
  else
    local git_init_output
    git_init_output=$(execute_call_in "$project_directory" git init)
    local git_init_status=$?

    if [ $git_init_status -ne 0 ]; then
      print_status "error" "git_init" "Failed to initialize local git repository in '$project_directory'. Message: $git_init_output"
      return $git_init_status
    else
      print_status "success" "git_init" "Initialize local git repository"
      return 0
    fi
  fi
}


# @description Add a remote origin to a git repository if it doesn't already
# exist
# @example
#   git_remote_add <project_directory> <organization_name> <repository_name>
#
# @arg $1 Project directory.
# @arg $2 Organization name.
# @arg $3 Repository name.
#
# @exitcode 0  If the remote origin was added successfully.
# @exitcode 1  If any error occurred.
git_remote_add() {
  if [ "$#" -ne 3 ]; then
    print_status "error" "git_remote_add" "Usage git_remote_add <project_directory> <organization_name> <repository_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local organization_name="$2"
  local repository_name="$3"

  local origin_url="https://github.com/$organization_name/$repository_name.git"

  local git_remote_output
  git_remote_output=$(execute_call_in "$project_directory" git remote add origin $origin_url)
  local git_remote_status=$?

  if [ $git_remote_status -eq 0 ]; then
    print_status "success" "git_remote_add" "Add remote 'origin'"
    return 0
  fi

  if [ $git_remote_status -eq 3 ]; then
    print_status "skipped" "git_remote_add" "Remote 'origin' exists"
    return 0
  fi

  print_status "error" "git_remote_add" "Failed to add remote 'origin' '$origin_url'. Message: $git_remote_output"
  return $git_remote_status
}


# @description Checkout a branch if it exists or create a new branch
# @example
#   git_checkout <project_directory> <branch_name>
#
# @arg $1 Project directory.
# @arg $2 Branch name.
#
# @exitcode 0  If the branch was checked out successfully.
# @exitcode 1  If any error occurred.
git_checkout() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "git_checkout" "Usage git_checkout <project_directory> <branch_name> to checkout an existing branch or create a new branch. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local branch_name="$2"

  # WAS WORKING ON THIS PART. HAVE A WEIRD ERROR OF

  # (action)      standard_version_first_release: Setting up first version along with first CHANGELOG.md entry in Staging
  # (error)         git_checkout: Failed to create and checkout branch 'Staging'. Message: fatal: a branch named 'Staging' exists

  # END

  if on_branch "$project_directory" "$branch_name"; then
    # we are often on the correct branch already, so we don't want to print this
    # print_status "skipped" "git_checkout" "Already on branch '$branch_name'"
    return 0
  fi

  if has_branch "$project_directory" "$branch_name"; then
    local git_checkout_output
    git_checkout_output=$(execute_call_in "$project_directory" git checkout "$branch_name")
    local git_checkout_status=$?

    if [ $git_checkout_status -eq 0 ]; then
      # we are often on the correct branch already, so we don't want to print this
      # print_status "skipped" "git_checkout" "Switch to an existing branch '$branch_name'"
      return 0
    else
      print_status "error" "git_checkout" "Failed to checkout branch '$branch_name'. Message: $git_checkout_output"
      return $git_checkout_status
    fi
  else
    local git_checkout_new_output
    git_checkout_new_output=$(execute_call_in "$project_directory" git checkout -b "$branch_name")
    local git_checkout_new_status=$?

    if [ $git_checkout_new_status -eq 0 ]; then
      print_status "success" "git_checkout" "Switch to a new branch '$branch_name'"
      return 0
    else
      print_status "error" "git_checkout" "Failed to create and checkout branch '$branch_name'. Message: $git_checkout_new_output"
      return $git_checkout_new_status
    fi
  fi
}

# @description Commit changes to a feature branch. If the particular feature
# has already been committed, then skip the commit.
# @example
#   git_feature_commit <project_directory> <branch_name> <commit_type> <commit_scope> <branch_title> <branch_details> <feature_name> <issue_number> [options]
#
# @arg $1 Project directory.
# @arg $2 Branch name.
# @arg $3 Commit type. See https://www.conventionalcommits.org/en/v1.0.0/#specification for details.
# @arg $4 Commit scope. See https://www.conventionalcommits.org/en/v1.0.0/#specification for details.
# @arg $5 Branch title.
# @arg $6 Branch details.
# @arg $7 Feature name.
# @arg $8 Issue number.
# @arg $9 Git commit Options.
#
# @exitcode 0  If the commit was successful.
# @exitcode 1  If any error occurred.
git_feature_commit() {
  if [[ "$#" -ne 8 && "$#" -ne 9 ]]; then
    print_status "error" "git_feature_commit" "Usage git_feature_commit <project_directory> <branch_name> <commit_type> <commit_scope> <branch_title> <branch_details> <feature_name> <issue_number> [options]. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local branch_name="$2"
  local commit_type="$3"
  local commit_scope="$4"
  local branch_title="$5"
  local branch_details="$6"
  local feature_name="$7"
  local issue_number="$8"
  local options="$9"

  local commit_message="$commit_type($commit_scope): $branch_title

  $branch_details
  issue: #$issue_number
  feature: $feature_name
  "

  if ! feature_commit_exists "$project_directory" "$feature_name"; then
    print_status "skipped" "git_feature_commit" "Feature '$feature_name' exists. Skipping commit"
    return 0
  else
    if ! git_checkout $"$project_directory" "$branch_name"; then
      print_status "error" "git_feature_commit" "Failed to checkout branch '$branch_name'"
      return 1
    fi

    local git_commit_output
    git_commit_output=$(execute_call_in "$project_directory" git commit $options -m "$commit_message")
    local git_commit_status=$?

    if [ $git_commit_status -ne 0 ]; then
      print_status "error" "git_feature_commit" "Git commit failed with exit code $commit_status."
      return $git_commit_status
    fi

    print_status "success" "git_feature_commit" "Commit changes"
  fi
}

# @description Push a branch to the remote repository
# @example
#   git_push_origin <project_directory> <branch_name>
#
# @arg $1 Project directory.
# @arg $2 Branch name.
#
# @exitcode 0  If the branch was pushed successfully.
# @exitcode 1  If any error occurred.
#
# TODO: Need to look at this error message and let the user know that they need
# to pull the latest changes from the remote repository before they can run the
# scripts again.
# (error)         git_push_origin: Failed to push branch 'staging' to remote repository. Message: To https://github.com/erichosick/markdown-scripts.git
#  ! [rejected]        staging -> staging (fetch first)
# error: failed to push some refs to 'https://github.com/erichosick/markdown-scripts.git'
# hint: Updates were rejected because the remote contains work that you do
# hint: not have locally. This is usually caused by another repository pushing
# hint: to the same ref. You may want to first integrate the remote changes
# hint: (e.g., 'git pull ...') before pushing again.
# hint: See the 'Note about fast-forwards' in 'git push --help' for details.

git_push_origin() {
  if [ "$#" -ne 2 ]; then
    print_status "error" "git_push_origin" "Usage git_push_origin <project_directory> <branch_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local branch_name="$2"

  local git_push_output
  git_push_output=$(execute_call_in "$project_directory" git push origin "$branch_name")
  local git_push_status=$?

  if [ $git_push_status -ne 0 ]; then
    print_status "error" "git_push_origin" "Failed to push branch '$branch_name' to remote repository. Message: $git_push_output"
    return $git_push_status
  else
    if [[ "$git_push_output" =~ "Everything up-to-date" ]]; then
      print_status "skipped" "git_push_origin" "Branch '$branch_name' is up-to-date with remote repository"
    else
      print_status "success" "git_push_origin" "Push branch '$branch_name' to remote repository"
    fi
    return 0
  fi
}


git_tag_feature() {
  if [ "$#" -ne 4 ]; then
    print_status "error" "git_tag_feature" "Usage git_tag_feature <project_directory> <tag_name> <commit_type> <commit_scope>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local tag_name="$2"
  local commit_type="$3"
  local commit_scope="$4"

  local git_ref_output
  git_ref_output=$(execute_call_in "$project_directory" git show-ref --quiet --heads)
  local git_ref_status=$?

  if [ $git_ref_status -ne 0 ]; then
      print_status "error" "git_tag_feature" "The git repository in $project_directory requires at least one commit before a tag can be created"
    return $git_ref_status
  fi

  git_tag_not_exists "$project_directory" "$tag_name"
  local git_tag_not_exists_status=$?

  if [ $git_tag_not_exists_status -eq 2 ]; then
    print_status "skipped" "git_tag_feature" "Tag '$tag_name' exists"
    return 0
  fi

  if [ $git_tag_not_exists_status -ne 0 ]; then
    # error message already printed
    return 0
  fi

  local git_tag_output
  git_tag_output=$(execute_call_in "$project_directory" git tag $tag_name -m "$commit_scope $branch_title")
  local git_tag_status=$?

  if [ $git_tag_status -ne 0 ]; then
    print_status "error" "git_tag_feature" "Failed to create tag '$tag_name': $git_tag_output"
    return $git_tag_status
  else
    print_status "success" "git_tag_feature" "Create tag '$tag_name': $git_tag_output"
    return 0
  fi
}


git_push_tags() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "git_push_tags" "Usage git_push_tags <project_directory>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"

  local git_push_tags_output
  git_push_tags_output=$(execute_call_in "$project_directory" git push origin --tags)
  local git_push_tags_status=$?

  if [ $git_push_tags_status -ne 0 ]; then
    print_status "error" "git_push_tags" "Failed to push tags to remote repository: $git_push_tags_output"
    return $git_push_tags_status
  else
    if [ "Everything up-to-date" = "$git_push_tags_output" ]; then
      print_status "skipped" "git_push_tags" "All tags are up-to-date with remote repository"
    else
      print_status "success" "git_push_tags" "Push tags to remote repository"
    fi
  fi
}

git_current_head() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "git_current_head" "Usage git_current_head <project_directory>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"

  local git_current_head_output
  git_current_head_output=$(execute_call_in "$project_directory" git rev-parse HEAD)
  local git_current_head_status=$?

  if [ $git_current_head_status -ne 0 ]; then
    print_status "error" "git_current_head" "Failed to get current HEAD: $git_current_head_output"
    return $git_current_head_status
  else
    echo "$git_current_head_output"
    return 0
  fi
}

git_current_head_short() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "git_current_head_short" "Usage git_current_head_short <project_directory>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"

  local git_current_head_short_output
  git_current_head_short_output=$(execute_call_in "$project_directory" git rev-parse --short HEAD)
  local git_current_head_short_status=$?

  if [ $git_current_head_short_status -ne 0 ]; then
    print_status "error" "git_current_head_short" "Failed to get current HEAD: $git_current_head_short_output"
    return $git_current_head_short_status
  else
    echo "$git_current_head_short_output"
    return 0
  fi
}

# @description Merge the staging branch into main
git_push_main() {
  if ["$#" -ne 2 ]; then
    print_status "error" "git_publish_version" "Usage git_merge_main <project_directory> <branch_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local branch_name="$2"

  # git_checkout "$project_directory" "main" || return $?

  # local git_merge_output
  # git_merge_output=$(execute_call_in "$project_directory" git merge "$branch_name")
  # local git_merge_status=$?

  # if [ $git_merge_status -ne 0 ]; then
  #   print_status "error" "git_merge_main" "Failed to merge branch '$branch_name' into main: $git_merge_output"
  #   return $git_merge_status
  # else
  #   if [ "Already up to date." = "$git_merge_output" ]; then
  #     print_status "skipped" "git_merge_main" "Branch '$branch_name' is already merged into main"
  #   else
  #     print_status "success" "git_merge_main" "Merged branch '$branch_name' into main $git_merge_output"
  #   fi
  # fi

  # git_push_origin "$project_directory" "main" || return $?  
}

git_setup() {
  if [ "$#" -ne 3 ]; then
    print_status "error" "git_setup" "Usage git_setup <project_directory> <organization_name> <repository_name>. Values(s) passed were '$#'"
    return 1
  fi

  local project_directory="$1"
  local organization_name="$2"
  local repository_name="$3"

  print_status "action" "git_setup" "Initilize git repository '$repository_name' and add remote origin"

  # Create a new public GitHub repository if it doesn't exist
  gh_repo_create "$project_directory" "$organization_name" "$repository_name" || return $?

  # initialize the git repository if it doesn't already exist
  git_init "$project_directory" || return $?

  # Add the remote 'origin' if it doesn't already exist
  git_remote_add "$project_directory" "$organization_name" "$repository_name" || return $?
}
