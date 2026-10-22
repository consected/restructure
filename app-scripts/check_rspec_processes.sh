#!/usr/bin/env bash
# Report RSpec processes whose working directory is inside the current workspace.

usage() {
  echo "Usage: $0 [workspace-path]" >&2
  echo "Exit status is 0 when none are running, 1 when one or more are found." >&2
}

if [[ $# -gt 1 ]]; then
  usage
  exit 2
fi

workspace_path=${1:-.}
if workspace_root=$(git -C "${workspace_path}" rev-parse --show-toplevel 2>/dev/null); then
  :
elif workspace_root=$(cd "${workspace_path}" 2>/dev/null && pwd -P); then
  :
else
  echo "Could not resolve workspace path: ${workspace_path}" >&2
  exit 2
fi
workspace_root=$(cd "${workspace_root}" && pwd -P)

found=0
while read -r pid process_command; do
  [[ "${pid}" == "$$" ]] && continue
  [[ "${process_command}" =~ (^|[[:space:]/])rspec([[:space:]]|$) ]] || continue

  process_cwd=$(readlink -f "/proc/${pid}/cwd" 2>/dev/null) || continue
  [[ "${process_cwd}" == "${workspace_root}" || "${process_cwd}" == "${workspace_root}/"* ]] || continue

  test_env_set=$(tr '\0' '\n' < "/proc/${pid}/environ" 2>/dev/null | sed -n 's/^TEST_ENV_SET=//p' | head -n 1)
  test_env_number=$(tr '\0' '\n' < "/proc/${pid}/environ" 2>/dev/null | sed -n 's/^TEST_ENV_NUMBER=//p' | head -n 1)
  test_env_set=${test_env_set:-<unset>}
  test_env_number=${test_env_number:-<unset>}

  if [[ ${found} -eq 0 ]]; then
    printf '%-8s %-12s %-12s %-40s %s\n' 'PID' 'TEST_ENV_SET' 'TEST_ENV_NUMBER' 'WORKING_DIRECTORY' 'COMMAND'
  fi
  printf '%-8s %-12s %-12s %-40s %s\n' \
    "${pid}" "${test_env_set}" "${test_env_number}" "${process_cwd}" "${process_command}"
  found=1
done < <(ps -eo pid=,args=)

if [[ ${found} -eq 0 ]]; then
  echo "No RSpec processes found under ${workspace_root}."
  exit 0
fi

exit 1
