#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  source "${BATS_TEST_DIRNAME}/../../../src/readi/main.sh"
  TEST_ROOT="$(mktemp -d)"
  CALLS=()
  ARGUMENTS=()

  shell_md_readi_canonize() {
    CALLS+=(canonize)
    ARGUMENTS+=("${1}")
    SHELL_MD_READI_RESULT_CANONIZE=canonical-payload
  }
  shell_md_readi_parse() {
    CALLS+=(parse)
    ARGUMENTS+=("${1}")
  }
  shell_md_readi_format() {
    CALLS+=(format)
    ARGUMENTS+=("${1}")
    SHELL_MD_READI_RESULT_FORMAT=formatted-output
  }
}

teardown() {
  rm -rf -- "${TEST_ROOT}"
}

@test "missing source or target arguments fail before reading or invoking collaborators" {
  run --separate-stderr shell_md_readi_process_file "" "${TEST_ROOT}/out.md"
  [[ ${status} -eq 1 && -z ${output} && ${stderr} == "[ERR] :: Missing source file." ]] || return 1
  [[ ${#CALLS[@]} -eq 0 ]] || return 1

  run --separate-stderr shell_md_readi_process_file "${TEST_ROOT}/input.md" ""
  [[ ${status} -eq 1 && -z ${output} && ${stderr} == "[ERR] :: Missing target file." ]] || return 1
  [[ ${#CALLS[@]} -eq 0 ]]
}

@test "reads the source, runs the three phases in order, and creates nested output parents" {
  local source="${TEST_ROOT}/input.md" target="${TEST_ROOT}/nested/deeper/output.md"
  printf "%s" "raw first line
raw second line" > "${source}"

  run --separate-stderr shell_md_readi_process_file "${source}" "${target}"
  [[ ${status} -eq 0 && -z ${output} && -z ${stderr} ]] || return 1
  [[ -f ${target} && $(<"${target}") == formatted-output ]] || return 1

  CALLS=()
  ARGUMENTS=()
  shell_md_readi_process_file "${source}" "${target}" || return 1
  [[ ${CALLS[*]} == "canonize parse format" && ${#CALLS[@]} -eq 3 ]] || return 1
  [[ ${ARGUMENTS[0]} == "raw first line
raw second line" ]] || return 1
  [[ ${ARGUMENTS[1]} == canonical-payload && ${ARGUMENTS[2]} == canonical-payload ]]
}

@test "in-place processing replaces the source contents with the formatted result" {
  local source="${TEST_ROOT}/in-place.md"
  printf "%s" original-content > "${source}"

  shell_md_readi_process_file "${source}" "${source}" || return 1
  [[ $(<"${source}") == formatted-output ]] || return 1
  [[ ${CALLS[*]} == "canonize parse format" && ${ARGUMENTS[0]} == original-content ]]
}
