# Description: This file contains functions that are useful for bash scripting.

# @description Resolves a path (removing ~, . and ..) and errors if the path
# does not exit. If you want to resolve a path that doesn't need to exist then
# use normalize_path.
# @example
#   resolve_path "~/path1/path2/../path3/./file.txt"
# returns /home/user/path1/path3/file.txt
# @arg $1 string File path.
#
# @exitcode 0  If the path was resolved successfully.
# @exitcode 1  If any error occurred.
resolve_path() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "resolve_path" "Usage resolve_path <file_path>. Values(s) passed were '$#'"
    return 1
  fi

  local file_path="$1"

  # Expand tilde to $HOME if it's the first character
  local file_path_no_tilde="${file_path/#\~/$HOME}"
  local resolved_path
  resolved_path=$(realpath "$file_path_no_tilde")

  if [ -z "$resolved_path" ]; then
    print_status "error" "resolve_path" "Failed to resolve path'$file_path'"
    { echo ""; return 1; }
  fi

  { echo "$resolved_path"; return 0; }
}

normalize_path() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "normalize_path" "Usage normalize_path <file_path>. Values(s) passed were '$#'"
    return 1
  fi

  local file_path="$1"

  # Realize the home directory by replacing "~" with "$HOME"
  # Note that we are checking for the literal "~" passed. If the user calls
  # the function with ~ (not in quotes) that is automatically resovled by
  # bash to be the home directory.
  if [[ $file_path == .* ]]; then
    file_path="${file_path/#./$PWD}"
  elif [[ $file_path == "~"* ]]; then
    # Realize the current directroy by replacing "./" with "$PWD/"
    file_path="${1/#\~/$HOME}"
  fi

  # remove "empty" file_path: replace "/./" with "/"
  while [[ "$file_path" == *"/./"* ]]; do
    file_path="${file_path//\/.\///}"
  done

  # we have removed all of the "/./" but there may be a trailing one left
  # remove any file_path that ends with /.
  if [[ "$file_path" == *"/." ]]; then
    file_path="${file_path//\/.}"
  fi

  # TODO: Resolve .. file_path segments

  echo "$file_path"
}


# @description Creates a directory if it does not already exist printing the
#   appropriate status message.
# @example
#   make_directory "my_directory"
#
# @arg $1 string Directory name.
#
# @exitcode 0  If the directory was created successfully.
# @exitcode 1  If any error occurred.
make_directory() {
  if [[ "$#" -ne 1 && "$#" -ne 2 ]]; then
    print_status "error" "make_directory" "Usage make_directory <directory_name> [options] where options = -q for quiet. Values(s) passed were '$#'"
    return 1
  fi

  local directory_name="$1"
  local quiet="${2:-false}"
  
  # Check if the directory exists so we can let the user know
  if [ -d "$directory_name" ]; then
    if [ "$quiet" != "-q" ]; then
      print_status "skipped" "make_directory" "Directory '$directory_name' exists."
    fi
    return 0
  fi

  # Create the directory and capture the output and exit status
  local mkdir_call_message
  mkdir_call_message=$(mkdir -p "$directory_name" 2>&1)
  local mkdir_call_exit_status=$?

  # Handle the result of the mkdir call
  if [ "$mkdir_call_exit_status" -ne 0 ]; then
    print_status "error" "make_directory" "$mkdir_call_message"
    return mkdir_call_exit_status
  else
    print_status "success" "make_directory" "Directory '$directory_name' created successfully."
    return 0
  fi
}

# @description Verifies that a file exists.
# @example
#   file_exists "my_file"
#
# @arg $1 string File path.
#
# @exitcode 0  If the file exists.
# @exitcode 1  If any error occurred.
file_exists() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "file_exists" "Usage file_exists <file_path>. Values(s) passed were '$#'"
    return 1 
  fi

  local file="$1"

  # Need to expand to use $HOME bcaues calling with quotes, 
  # file_exists "~/some_file.txt", errors
  local file_path_real="${file_path/#\~/$HOME}"  # Expand tilde to $HOME if it's the first character  

  [ -f "$file_path_real" ] && return 0 || return $?
}

file_exists_status() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "file_exists_status" "Usage file_exists_status <file_path>. Values(s) passed were '$#'"
    return 1 
  fi

  local file_path="$1"

  if ! file_exists "$file_path"; then
    print_status "error" "file_exists_status" "File '$file_path' does not exist."
    return 1
  fi

  return 0
}

touch_file() {
  if [ "$#" -ne 1 ]; then
    print_status "error" "create_file" "Usage create_file <file_path>. Values(s) passed were '$#'"
    return 1
  fi

  local file_path="$1"

  if file_exists "$file_path"; then
    print_status "skipped" "create_file" "File '$file_path' exists."
    return 0
  fi

  local touch_call_message
  touch_call_message=$(touch "$file_path" 2>&1)
  local touch_call_exit_status=$?

  if [ "$touch_call_exit_status" -ne 0 ]; then
    print_status "error" "create_file" "Unable to create file '$file_path'. $touch_call_message"
    return $touch_call_exit_status
  else
    print_status "success" "create_file" "Create file '$file_path'"
    return 0
  fi
}

# @description Verifies that the parameter provided is a valid array.
# @example
#   is_array "(1 2 3)"
#
# @arg $1 string Array to verify.
#
# @exitcode 0  If the array is valid.
# @exitcode 1  If any error occurred.
is_array() {
  if [ "$#" -eq 0 ]; then
    print_status "error" "is_array" "Usage is_array <variable_name>. Values(s) passed were '$#'"
    return 1
  fi

  local variable_name=("$@")

  [[ "$(declare -p variable_name)" =~ "declare -a" ]] && return 0 || return 1
}

# @description Gets the realpath of a file or directory.
# @example
#   real_path "my_file" -q
#
# @arg $1 string File or directory path.
# @arg $2 string Optional argument to suppress printing the result
#
# @exitcode 0  If the path was resolved successfully.
# @exitcode 1  If any error occurred.
real_path() {
  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    print_status "error" "real_path" "Usage real_path <file_or_directory> [-q] where -q is optional and will suppress the output of the function. Values(s) passed were '$#'"
    return 1
  fi

  local path="$1"
  local quiet="${2:-false}"
  local resolved_path
  resolved_path=$(realpath "$path" 2>/dev/null)

  if [ -z "$resolved_path" ]; then
    if [ "$quiet" != "-q" ]; then
      print_status "error" "real_path" "Failed to resolve the path: '$path'"
    fi
    return 1
  fi

  echo "$resolved_path"
  return 0
}

# @description Verifies that a function has been defined and is in scope.
# @example
#   function_exists "my_function"
#
# @arg $1 string Function name.
#
# @exitcode 0  If the function exists.
# @exitcode 1  If any error occurred.
function_exists() {
  if [ "$#" -ne 1 ]; then
    echo "function_exists: Usage function_exists <function_name>. Values(s) passed were '$#'"
    return 1
  fi

  local function_name="$1"
  type "$function_name" &> /dev/null && return 0 || return 1
}

# @description Wrapps a command in a function and captures the output: exiting
# with the status
# @example
#   local output
#   output=$(execute_call mkdir hello)
#   local exit_status=$?
#
# @arg $@ The command to execute, including any arguments.
#
# @exitcode ?  The exit status of the command.
execute_call() {
  # Execute the command and capture output
  local output
  output=$("$@" 2>&1)
  local exit_status=$?

  # The output is re-echoed so that it can be captured by the caller
  echo "$output"

  # Return the captured exit status
  return $exit_status
}

# @description Changes to the directory provided, then runs the provied command,
# captures the output and exits with the status
# @example
#   local output
#   output=$("../somedir" execute_call mkdir hello)
#   local exit_status=$?
#
# @arg $1 The directory to change to.
# @arg $@ (additional params) The command to execute, including any arguments.
#
# @exitcode ?  The exit status of the command.
execute_call_in() {
  local project_directory="$1"
  shift  # Remove the first argument and use the rest for the command

  # Use a subshell to change directory, execute the command, and capture output
  local output
  output=$(cd "$project_directory" && "$@" 2>&1)
  local exit_status=$?

  # Echo the captured output
  echo "$output"

  # Return the captured exit status
  return $exit_status
}
