#!/usr/bin/env bash
set -e

DOTENV_FILE="$1"
[ -f "${DOTENV_FILE}" ] || { echo "${DOTENV_FILE} must be a valid file" >&2; exit 1; }

is_set() {
  eval val=\""\$$1"\"
  if [ -z "$(eval "echo \$$1")" ]; then
    return 1
  else
    return 0
  fi
}

is_comment() {
  case "$1" in
  \#*)
    return 0
    ;;
  esac
  return 1
}

is_blank() {
  case "$1" in
  '')
    return 0
    ;;
  esac
  return 1
}

export_envs() {
  while IFS='=' read -r key || [ -n "$key" ]; do
    if is_comment "$key"; then
      continue
    fi
    if is_blank "$key"; then
      continue
    fi
    eval export "$key=''";
    echo "::set-env name=$key::"
  done < $1
}

export_envs "$DOTENV_FILE"