#!/usr/bin/env bats

# Summary: Load the orchestrator and replace its collaborators with traceable stubs.
# Effects: Initializes the orchestrator result and per-test call/argument logs.
setup() {
  bats_require_minimum_version 1.5.0
  source "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize.sh"
  CALLS=()
  ARGUMENTS=()
  shell_md_readi_canonize_characters() {
    CALLS+=(characters)
    ARGUMENTS+=("${1}")
    SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS=after-characters
  }
  shell_md_readi_canonize_blank_lines() {
    CALLS+=(blank_lines)
    ARGUMENTS+=("${1}")
    SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES=after-blank_lines
  }
  shell_md_readi_canonize_headers() {
    CALLS+=(headers)
    ARGUMENTS+=("${1}")
    SHELL_MD_READI_RESULT_CANONIZE_HEADERS=after-headers
  }
  shell_md_readi_canonize_blockquotes() {
    CALLS+=(blockquotes)
    ARGUMENTS+=("${1}")
    SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES=after-blockquotes
  }
  shell_md_readi_canonize_content_lines() {
    CALLS+=(content_lines)
    ARGUMENTS+=("${1}")
    SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES=after-content_lines
  }
  shell_md_readi_canonize_table_cells() {
    CALLS+=(table_cells)
    ARGUMENTS+=("${1}")
    SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS=after-table_cells
  }
  shell_md_readi_canonize_indentation() {
    CALLS+=(indentation)
    ARGUMENTS+=("${1}")
    SHELL_MD_READI_RESULT_CANONIZE_INDENTATION=after-indentation
  }
}

@test "empty and omitted payloads clear the public result and fail before collaborators" {
  SHELL_MD_READI_RESULT_CANONIZE=stale
  run --separate-stderr shell_md_readi_canonize ""
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
  [ "${stderr}" = "[ERR] :: Missing content payload for canonization." ]
  if shell_md_readi_canonize "" 2>/dev/null; then return 1; fi
  [ -z "${SHELL_MD_READI_RESULT_CANONIZE}" ]
  [ "${#CALLS[@]}" -eq 0 ]

  SHELL_MD_READI_RESULT_CANONIZE=stale-again
  run --separate-stderr shell_md_readi_canonize
  [ "${status}" -eq 1 ]
  [ -z "${output}" ]
  [ "${stderr}" = "[ERR] :: Missing content payload for canonization." ]
  if shell_md_readi_canonize 2>/dev/null; then return 1; fi
  [ -z "${SHELL_MD_READI_RESULT_CANONIZE}" ]
  [ "${#CALLS[@]}" -eq 0 ]
}

@test "nonempty payload flows through collaborators exactly once in declared order" {
  local payload=$'  first line\nsecond\tline  '
  run --separate-stderr shell_md_readi_canonize "${payload}"
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  [ -z "${stderr}" ]

  shell_md_readi_canonize "${payload}"
  [ "${CALLS[*]}" = "characters blank_lines headers blockquotes content_lines table_cells indentation" ]
  [ "${#CALLS[@]}" -eq 7 ]
  [ "${ARGUMENTS[0]}" = "${payload}" ]
  [ "${ARGUMENTS[1]}" = after-characters ]
  [ "${ARGUMENTS[2]}" = after-blank_lines ]
  [ "${ARGUMENTS[3]}" = after-headers ]
  [ "${ARGUMENTS[4]}" = after-blockquotes ]
  [ "${ARGUMENTS[5]}" = after-content_lines ]
  [ "${ARGUMENTS[6]}" = after-table_cells ]
  [ "${SHELL_MD_READI_RESULT_CANONIZE}" = after-indentation ]
}

@test "whitespace-only payload is valid and reaches the full pipeline unchanged" {
  local payload=$' \t '
  run --separate-stderr shell_md_readi_canonize "${payload}"
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  [ -z "${stderr}" ]

  shell_md_readi_canonize "${payload}"
  [ "${ARGUMENTS[0]}" = "${payload}" ]
  [ "${#CALLS[@]}" -eq 7 ]
  [ "${SHELL_MD_READI_RESULT_CANONIZE}" = after-indentation ]
}
