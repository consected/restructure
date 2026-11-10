#!/usr/bin/env bash
# Report (and optionally stop) Selenium/WebDriver-controlled browsers left behind by spec runs in this workspace.
#
# Matches chromedriver, geckodriver and browsers started with --test-type=webdriver (Chrome) or
# --marionette (Firefox), which covers Capybara system specs and jasmine-browser-runner. A browser
# started by hand, or by another automation tool such as Playwright, has none of these and is ignored.
# Ownership is decided by the working directory of the process, as in check_rspec_processes.sh.
# Processes that belong to another workspace are listed but never stopped.
#
# Usage: app-scripts/check_capybara_browsers.sh [--kill] [--force] [workspace-path]
#   --kill   stop the drivers and browsers that belong to this workspace
#   --force  with --kill, stop them even if an RSpec or Jasmine run is active in this workspace
# Exit status: 0 when none belong to the workspace (or all were stopped), 1 when some remain,
# 2 on a usage error or when --kill was refused because a run is active.

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

usage() {
  echo "Usage: $0 [--kill] [--force] [workspace-path]" >&2
  echo "Exit status is 0 when none belong to the workspace (or all were stopped), 1 when some remain, 2 on error." >&2
}

kill_mode=0
force=0
workspace_path=.
for arg in "$@"; do
  case "${arg}" in
    --kill) kill_mode=1 ;;
    --force) force=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      usage
      exit 2
      ;;
    *) workspace_path=${arg} ;;
  esac
done

if workspace_root=$(git -C "${workspace_path}" rev-parse --show-toplevel 2>/dev/null); then
  :
elif workspace_root=$(cd "${workspace_path}" 2>/dev/null && pwd -P); then
  :
else
  echo "Could not resolve workspace path: ${workspace_path}" >&2
  exit 2
fi
workspace_root=$(cd "${workspace_root}" && pwd -P)

in_workspace() {
  [[ "$1" == "${workspace_root}" || "$1" == "${workspace_root}/"* ]]
}

# Sets kind to driver, browser or helper (a browser's child process) for WebDriver processes, or '' otherwise.
classify() {
  local command_line=$1 exe
  kind=''
  exe=${command_line%% *}
  exe=${exe##*/}
  case "${exe}" in
    chromedriver | geckodriver | firefox.geckodriver)
      kind=driver
      ;;
    *chrom* | *firefox*)
      case "${command_line}" in
        *' --test-type=webdriver'* | *' --marionette'*) kind=browser ;;
      esac
      if [[ -n "${kind}" && ("${command_line}" == *' --type='* || "${command_line}" == *' -contentproc'*) ]]; then
        kind=helper
      fi
      ;;
  esac
}

# Succeeds when an RSpec or Jasmine run is active in this workspace, so its browsers are in use.
active_run_in_workspace() {
  "${script_dir}/check_rspec_processes.sh" "${workspace_root}" > /dev/null || return 0

  local pid process_command process_cwd
  while read -r pid process_command; do
    [[ "${pid}" == "$$" ]] && continue
    [[ "${process_command}" == *jasmine-browser-runner* ]] || continue

    process_cwd=$(readlink -f "/proc/${pid}/cwd" 2>/dev/null) || continue
    in_workspace "${process_cwd}" && return 0
  done < <(ps -eo pid=,args=)
  return 1
}

declare -A ppid_of command_of kind_of cwd_of owned
all_pids=()
while read -r pid ppid process_command; do
  [[ "${pid}" == "$$" ]] && continue
  all_pids+=("${pid}")
  ppid_of[${pid}]=${ppid}
  command_of[${pid}]=${process_command}

  [[ "${process_command}" == *chrom* || "${process_command}" == *firefox* || "${process_command}" == *geckodriver* ]] || continue
  classify "${process_command}"
  [[ -n "${kind}" ]] || continue

  kind_of[${pid}]=${kind}
  process_cwd=$(readlink -f "/proc/${pid}/cwd" 2>/dev/null) || process_cwd='<unknown>'
  cwd_of[${pid}]=${process_cwd}
  in_workspace "${process_cwd}" && owned[${pid}]=1
done < <(ps -eo pid=,ppid=,args=)

# Anything started by an owned driver or browser is also ours
changed=1
while [[ ${changed} -eq 1 ]]; do
  changed=0
  for pid in "${all_pids[@]}"; do
    [[ -n "${owned[${pid}]:-}" ]] && continue
    if [[ -n "${owned[${ppid_of[${pid}]}]:-}" ]]; then
      owned[${pid}]=1
      changed=1
    fi
  done
done

owned_listed=()
owned_all=()
other_listed=()
helper_count=0
for pid in "${all_pids[@]}"; do
  kind=${kind_of[${pid}]:-}
  if [[ -n "${owned[${pid}]:-}" ]]; then
    owned_all+=("${pid}")
    if [[ "${kind}" == driver || "${kind}" == browser ]]; then
      owned_listed+=("${pid}")
    else
      helper_count=$((helper_count + 1))
    fi
  elif [[ "${kind}" == driver || "${kind}" == browser ]]; then
    other_listed+=("${pid}")
  fi
done

if [[ ${#owned_listed[@]} -gt 0 || ${#other_listed[@]} -gt 0 ]]; then
  printf '%-8s %-8s %-10s %-40s %s\n' 'PID' 'KIND' 'OWNER' 'WORKING_DIRECTORY' 'COMMAND'
  for pid in "${owned_listed[@]}"; do
    printf '%-8s %-8s %-10s %-40s %s\n' "${pid}" "${kind_of[${pid}]}" 'workspace' "${cwd_of[${pid}]}" "${command_of[${pid}]:0:100}"
  done
  for pid in "${other_listed[@]}"; do
    printf '%-8s %-8s %-10s %-40s %s\n' "${pid}" "${kind_of[${pid}]}" 'other' "${cwd_of[${pid}]}" "${command_of[${pid}]:0:100}"
  done
fi

if [[ ${#other_listed[@]} -gt 0 ]]; then
  echo "${#other_listed[@]} driver/browser process(es) belong to another workspace and are left alone."
fi

if [[ ${#owned_all[@]} -eq 0 ]]; then
  echo "No WebDriver-controlled browsers found under ${workspace_root}."
  exit 0
fi

echo "${#owned_listed[@]} driver/browser process(es) (plus ${helper_count} helper process(es)) found under ${workspace_root}."

if [[ ${kill_mode} -eq 0 ]]; then
  exit 1
fi

if [[ ${force} -eq 0 ]] && active_run_in_workspace; then
  echo "An RSpec or Jasmine run is active in this workspace, so these browsers may be in use. Not stopping them (use --force to override)." >&2
  exit 2
fi

echo "Stopping them..."
kill -TERM "${owned_all[@]}" 2>/dev/null

remaining=("${owned_all[@]}")
for _ in 1 2 3 4 5 6 7 8 9 10; do
  still_running=()
  for pid in "${remaining[@]}"; do
    kill -0 "${pid}" 2>/dev/null && still_running+=("${pid}")
  done
  remaining=("${still_running[@]}")
  [[ ${#remaining[@]} -eq 0 ]] && break
  sleep 0.5
done

if [[ ${#remaining[@]} -gt 0 ]]; then
  kill -KILL "${remaining[@]}" 2>/dev/null
  sleep 0.5
  still_running=()
  for pid in "${remaining[@]}"; do
    kill -0 "${pid}" 2>/dev/null && still_running+=("${pid}")
  done
  remaining=("${still_running[@]}")
fi

if [[ ${#remaining[@]} -gt 0 ]]; then
  echo "Could not stop: ${remaining[*]}" >&2
  exit 1
fi

echo "Stopped."
exit 0
