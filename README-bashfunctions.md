Here is the basic form of all the bash functions we create. Just reply withe yes if you understand this.

1) Validate the call (example follows) calling print_status as needed. An Example:

  if [ "$#" -ne 1 ]; then
    print_status "error" "git_init" "Usage git_init <local_project_directory>"
    return 1
  fi

2) Capture the function parameters in local variables. An Example:

  local local_project_directory="$1"

3) Setup some global context (like changing to some directory): For example (an optional based on the function):

  pushd "$local_project_directory" >/dev/null || return 1

4) For each thing we need to do:

4a) make the specific calls capturing any errors or echoed messages, providing a print_status of the error along with returning 1. For example:

  # WARNING: Never declare the variable on the same line as the assignment.
  # the exit_status will always be 0 because the exit status we would read
  # is the exit status of declaring the local and not calling the function
  # itself
  local git_call_message
  git_call_message=$(git init 2>&1)
  local git_call_exit_status=$?

4b) handle the result of the call, for example:

if [ "$git_exit_status" -ne 1 ]; then
    print_status "error" "git_init" "Git init failed with exit status $git_call_exit_status. Error message: $git_call_message"

    # UNDO ANYTHING YOU DID IN THE FUNCTION context specific 
    popd >/dev/null
    return 1
else
    print_status "success" "git_init" "$git_call_message"
fi #
end if

4c) Loop for the next calls. Always remembering to handle the results of the call. We need to be very robust.

  go back to 4a

5) Cleanup any global context (like changing back to the original directory): For example (an optional based on the function):

  popd >/dev/null

6) Return 0 for success. Example:

  return 0