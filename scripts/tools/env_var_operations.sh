# Function: environment_variable_verify
# Purpose: Checks if a specified environment variable is set.
# Usage: environment_variable_verify "ENVIRONMENT_VARIABLE"
# Parameters:
#   environment_variable - Name of the environment variable to check.
#
# This function takes the name of an environment variable as an argument and
# checks if it is set. It returns 0 (true) if the variable is set, and 1 (false)
# if the variable is not set.
environment_variable_verify() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "environment_variable_verify" "Usage environment_variable_verify <environment_variable>. Values(s) passed were '$#'"
    return 1
  fi

  local environment_variable="$1"

  if [[ -z "${!environment_variable}" ]]; then
    return 1 # Return false
  else
    return 0 # Return true
  fi
}

# Function: environment_variables_verify
# Purpose: Checks if a specified list of environment variables are set.
# Usage: environment_variables_verify ("ENV_VAR_01" "ENV_VAR_02" ...)
# Parameters:
#   environment_variables - Array of environment variables to check.
#
# This function takes an array of environment variables as an argument and
# checks if they are set. It returns 0 (true) if all variables are set, and 1
# (false) if any of the variables are not set. 
environment_variables_verify() {
  if [ "$#" -eq 0 ]; then
    print_status "error" "environment_variables_verify" "Usage environment_variables_verify <array_of_environment_variables>. Values(s) passed were '$#'"
    return 1
  fi

  local env_vars=("$@")
  local missing_vars=""
  local is_first_missing_var=true

  for env_var in "${env_vars[@]}"; do
    # Trim leading and trailing whitespaces
    env_var=$(echo "$env_var" | xargs)

    if ! environment_variable_verify "$env_var"; then
      # Append the missing variable to the list
      if [ "$is_first_missing_var" = true ]; then
        missing_vars="$env_var"
        is_first_missing_var=false
      else
        missing_vars="$missing_vars, $env_var"
      fi
    fi
  done

  # Check if any environment variables were missing
  if [[ ! -z "$missing_vars" ]]; then
    print_status "error" "environment_variables_verify" "The following environment variables are required: $missing_vars" 

    # Return false
    return 1
  fi

  # Return true (0)
  return 0
}
