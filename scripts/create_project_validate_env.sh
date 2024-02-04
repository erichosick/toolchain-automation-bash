#!/bin/zsh

# Function to check if an environment variable is set
environment_variable_verify() {
    local var_name="$1"
    if [[ -z "${(P)var_name}" ]]; then
        missing_vars+=("$var_name")
    fi
}

# Array to hold the names of missing environment variables
missing_vars=()

# List of required environment variables
required_vars=("GITHUB_PERSONAL_ACCESS_TOKEN" "GITHUB_ORG_NAME" "GITHUB_ASSIGNEE"
               "PROJECT_NAME" "AUTHOR_NAME" "AUTHOR_EMAIL" "AUTHOR_URL"
               "PROJECT_DESCRIPTION" "PROJECT_LICENSE" "PROJECT_KEYWORDS"
               "README_ADDITIONAL" "PUBLISH_TO_GITHUB" "REPOSITORY_NAME")

# Check each environment variable
for var in $required_vars; do
    environment_variable_verify "$var"
done

# Report missing environment variables, if any
if (( ${#missing_vars[@]} > 0 )); then
    echo "Error: The following required environment variables are not set:"
    for var in $missing_vars; do
        echo "- $var"
    done
    exit 1
fi
