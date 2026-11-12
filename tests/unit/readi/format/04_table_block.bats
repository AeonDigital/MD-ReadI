#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  source "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  source "${BATS_TEST_DIRNAME}/../../../../src/readi/format/04_table_block.sh"
}

invoke_with_sentinels() {
  local rc=0
  shell_md_readi_format_table_block "${@}" || rc=${?}
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "${rc}"
}

assert_table() {
  local expected=${1}
  shift
  run --separate-stderr invoke_with_sentinels "${@}"
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]] || return 1

  shell_md_readi_format_table_block "${@}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK}" >&2
    return 1
  fi
}

@test "omitted, empty, whitespace-only, and blank-line input reset stale output" {
  SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK=stale
  assert_table ""
  [[ -z ${SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK} ]] || return 1

  SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK=stale
  assert_table "" " ${codeNL}	${codeNL}"
  [[ -z ${SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK} ]]
}

@test "data rows are trimmed and aligned to the widest cell in each column" {
  local input="| A | longer |${codeNL}|x|z|"
  local expected="| A   | longer |${codeNL}| x   | z      |${codeNL}"
  assert_table "${expected}" "${input}"
}

@test "divider rows render left, right, and center alignment with matching cell padding" {
  local input="| a | bbbb | xy |${codeNL}|:--|---:|:---:|${codeNL}| x | z | q |"
  local expected="| a   | bbbb | xy  |${codeNL}| --- | ---: | :-: |${codeNL}| x   |    z |  q  |${codeNL}"
  assert_table "${expected}" "${input}"
}

@test "minimum three-character widths apply to short cells and divider hyphens" {
  local input="|a|b|${codeNL}|-|--|${codeNL}|c|dd|"
  local expected="| a   | b   |${codeNL}| --- | --- |${codeNL}| c   | dd  |${codeNL}"
  assert_table "${expected}" "${input}"
}

@test "edge pipes are optional and empty outer cells and blank rows are ignored" {
  local input=" ${codeNL}  A | B  ${codeNL}${codeNL} | C | D | ${codeNL}"
  local expected="| A   | B   |${codeNL}| C   | D   |${codeNL}"
  assert_table "${expected}" "${input}"
}

@test "single-cell and ragged rows render using available widths and fallback minimums" {
  local input="plain${codeNL}|a|${codeNL}|b|c|d|"
  local expected="| plain |${codeNL}| a     |${codeNL}| b     | c   | d   |${codeNL}"
  assert_table "${expected}" "${input}"
}

@test "UTF-8 cell widths count characters rather than encoded bytes" {
  local input="| é | x |${codeNL}| u | ü |"
  local expected="| é   | x   |${codeNL}| u   | ü   |${codeNL}"
  assert_table "${expected}" "${input}"
}

@test "successive calls replace prior result and preserve the caller IFS" {
  local original_ifs=${IFS}
  assert_table "| first |${codeNL}" "| first |"
  [[ ${IFS} == "${original_ifs}" ]] || return 1

  assert_table "| second |${codeNL}" "| second |"
  [[ ${SHELL_MD_READI_RESULT_FORMAT_TABLE_BLOCK} == "| second |${codeNL}" && ${IFS} == "${original_ifs}" ]]
}
