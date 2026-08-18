#!/usr/bin/env bash

# shell_md_readi — Main orchestrator and entry point for the MD-ReadI formatting
# pipeline, managing path resolutions for both isolated files and directory trees.
# 
# Description:
# - Validates input parameters, enforcing strict target path constraints based on
#   the physical nature of the source (file-to-file or directory-to-directory).
# - Leverages native Bash globbing to recursively discover all target Markdown (.md)
#   assets when processing a directory tree structure.
# - Manages output destination routing, automatically switching between dynamic in-place
#   modification or isolated layout propagation to a mirrored target tree.
# 
# Arguments:
# - $1: String (Optional, but enforced) — Absolute or relative path to the source
#   Markdown file or directory containing the raw documentation.
# - $2: String (Optional) — Absolute or relative pathway pointing to the target destination.
#   If empty, the system defaults to strict in-place formatting.
# 
# Returns:
# - Dispatches validated file paths sequentially to the underlying process engine:
#   'shell_md_readi_process_file'.
# 
# Return Codes:
# - 0: On successful execution and processing of all discovered Markdown assets.
# - 1: If critical validations fail (missing parameters, missing paths, format mismatches,
#   or geometric target constraint violations).
shell_md_readi() {
  local source_path="${1:-}"
  local target_path="${2:-}"
  local source_file=""
  local target_file=""
  local rel_path=""
  local -a source_files=()

  if [ -z "${source_path}" ]; then
    printf "[ERR] :: Missing source path. Provide a file or directory.\n" >&2
    return 1
  fi

  if [ ! -e "${source_path}" ]; then
    printf "[ERR] :: Source path '%s' does not exist.\n" "${source_path}" >&2
    return 1
  fi

  if [ -f "${source_path}" ]; then
    if [[ ! "${source_path}" =~ \.md$ ]]; then
      printf "[ERR] :: Source file '%s' is not a Markdown (.md) file.\n" "${source_path}" >&2
      return 1
    fi

    if [ -z "${target_path}" ]; then
      target_file="${source_path}"
    else
      if [ -d "${target_path}" ]; then
        printf "[ERR] :: Second argument must be a file path when source is a file.\n" >&2
        return 1
      fi
      target_file="${target_path}"
    fi

    shell_md_readi_process_file "${source_path}" "${target_file}"
    return 0
  fi

  if [ -d "${source_path}" ]; then
    shopt -s globstar nullglob
    for source_file in "${source_path}"/**/*.md; do
      source_files+=("${source_file}")
    done
    shopt -u globstar nullglob

    if [ "${#source_files[@]}" -eq 0 ]; then
      printf "[ ! ] :: No Markdown (.md) files found under '%s'.\n" "${source_path}"
      return 0
    fi

    if [ -n "${target_path}" ]; then
      if [ -e "${target_path}" ] && [ ! -d "${target_path}" ]; then
        printf "[ERR] :: Second argument must be a directory path when source is a directory.\n" >&2
        return 1
      fi
      mkdir -p "${target_path}"
    fi

    for source_file in "${source_files[@]}"; do
      if [ -z "${target_path}" ]; then
        target_file="${source_file}"
      else
        rel_path="${source_file#"${source_path}"/}"
        target_file="${target_path}/${rel_path}"
      fi
      shell_md_readi_process_file "${source_file}" "${target_file}"
    done

    return 0
  fi

  printf "[ERR] :: Unsupported source path '%s'.\n" "${source_path}" >&2
  return 1
}



# shell_md_readi_process_file — Structural file processor that coordinates the lifecycle
# of an individual Markdown asset from raw disk ingestion to geometry transformation
# and filesystem output.
# 
# Description:
# - Acts as the primary execution junction that links physical I/O streams with the
#   in-memory processing pipelines governed by the MD-ReadI specification.
# - Drives the target string payload through three immutable architectural phases:
#   1. Canonization ('shell_md_readi_canonize'): Executes byte-level sanitation,
#      converts Setext to ATX, un-wraps loose prose lines, normalizes table alignments,
#      and encodes vertical breathing spaces into volatile density tokens (Specification
#      Sec 1, 2, 3 & 4).
#   2. Parsing ('shell_md_readi_parse'): Evaluates structural elements and local
#      block densities to construct a predictable contextual state blueprint (Specification
#      Sec 2 & 3).
#   3. Formatting ('shell_md_readi_format'): Programmatically reconstructs the final
#      text canvas, enforcing hard column wrapping limits (80-120 chars) and vertical
#      margins (Specification Sec 3, 4 & 5).
# - Minimizes processing overhead and bypasses heavy subshell forks by passing data
#   streams directly via global memory registers ('SHELL_MD_READI_RESULT_CANONIZE',
#   etc.).
# - Dynamically resolves the destination environment by automatically ensuring that
#   any nested target parent directory structure exists on disk prior to file persistence.
# 
# Arguments:
# - $1: String — Absolute or relative file system pathway pointing to the existing
#   source Markdown (.md) file to be processed.
# - $2: String — Absolute or relative file system pathway pointing to the target
#   destination where the formatted human-centric documentation must be preserved.
# 
# Returns:
# - Programmatically streams string payloads across localized sub-routines and outputs
#   the definitive, beautiful plain-text layout directly to the destination file.
# 
# Return Codes:
# - 0: Asset successfully canonized, parsed, formatted, and safely committed to physical
#   storage.
# - 1: Critical execution fault caused by unassigned parameters, empty references,
#   or I/O pathways.
shell_md_readi_process_file() {
  local source_file="${1:-}"
  local target_file="${2:-}"
  local raw_content=""
  local canonical_content=""
  local final_output=""

  if [ -z "${source_file}" ]; then
    printf "[ERR] :: Missing source file.\n" >&2
    return 1
  fi

  if [ -z "${target_file}" ]; then
    printf "[ERR] :: Missing target file.\n" >&2
    return 1
  fi

  raw_content="$(cat "${source_file}")"
  shell_md_readi_canonize "${raw_content}"
  shell_md_readi_parse "${SHELL_MD_READI_RESULT_CANONIZE}"
  shell_md_readi_format "${SHELL_MD_READI_RESULT_CANONIZE}"

  mkdir -p "$(dirname "${target_file}")"
  printf '%s' "${SHELL_MD_READI_RESULT_FORMAT}" > "${target_file}"
}
