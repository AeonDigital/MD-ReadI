#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  source "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  source "${BATS_TEST_DIRNAME}/../../../../src/share/01_links.sh"
  source "${BATS_TEST_DIRNAME}/../../../../src/readi/format/02_wrap_block.sh"
}

invoke_with_sentinels() {
  local rc=0
  shell_md_readi_format_wrap_block "${@}" || rc=${?}
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "${rc}"
}

assert_wrapped() {
  local input=${1}
  local expected=${2}
  shift 2

  run --separate-stderr invoke_with_sentinels "${input}" "${@}"
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]] || return 1

  shell_md_readi_format_wrap_block "${input}" "${@}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK} != "${expected}" ]]; then
    printf "expected %q, got %q${codeNL}" "${expected}" "${SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK}" >&2
    return 1
  fi
}

repeat_char() {
  local -n result_ref=${1}
  local char=${2}
  local count=${3}
  printf -v result_ref "%*s" "${count}" ""
  result_ref=${result_ref// /${char}}
}

@test "empty and omitted input reset stale output and emit nothing" {
  SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK=stale
  run --separate-stderr invoke_with_sentinels
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]]
  shell_md_readi_format_wrap_block
  [[ -z ${SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK} ]]

  SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK=stale
  assert_wrapped "" ""
  [[ -z ${SHELL_MD_READI_RESULT_FORMAT_WRAP_BLOCK} ]]
}

@test "the 80-column floor and whitespace positions at the 80-120 boundary are deterministic" {
  local a80= a119= a120= b= input= nl=${codeNL}
  repeat_char a80 A 80
  repeat_char a119 A 119
  repeat_char a120 A 120
  repeat_char b B 1

  assert_wrapped "${a80}" "${a80}${codeNL}"
  assert_wrapped "${a80} ${b}" "${a80}${codeNL}${b}${codeNL}"
  assert_wrapped "${a119} ${b}" "${a119}${codeNL}${b}${codeNL}"
  assert_wrapped "${a120} ${b}" "${a120}${codeNL}${b}${codeNL}"
}

@test "hard 120-column fallback accounts for first-line indentation" {
  local a118= b10= input= expected= nl=${codeNL}
  repeat_char a118 A 118
  repeat_char b10 B 10
  input="${a118} ${b10}"
  expected=" >${a118}${codeNL} >${b10}${codeNL}"

  assert_wrapped "${input}" "${expected}" " >"
}

@test "first and hanging prefixes govern successive comfort-window wraps" {
  local a80= b78= input= expected= nl=${codeNL}
  repeat_char a80 A 80
  repeat_char b78 B 78
  input="${a80} ${b78} C"
  expected=">>${a80}${codeNL}....${b78}${codeNL}....C${codeNL}"

  assert_wrapped "${input}" "${expected}" ">>" "...."
}

@test "unbroken atomic tokens are retained even beyond the hard wall" {
  local token= expected=
  repeat_char token x 121
  expected="${token}${codeNL}"
  assert_wrapped "${token}" "${expected}"
}

@test "hard-break whitespace is attached only to the final wrapped row" {
  local a80= input= expected= nl=${codeNL}
  repeat_char a80 A 80
  input="${a80} B  "
  expected="${a80}${codeNL}B  ${codeNL}"
  assert_wrapped "${input}" "${expected}"
  assert_wrapped "  " "first:  ${codeNL}" "first:" "rest:"
}

@test "link-internal spaces are not break points and a link remains intact" {
  local prefix= link= suffix= input= expected= nl=${codeNL}
  repeat_char prefix A 70
  link="[label with spaces](destination with spaces)"
  suffix="Z"
  input="${prefix} ${link} ${suffix}"
  expected="${prefix} ${link}${codeNL}${suffix}${codeNL}"

  assert_wrapped "${input}" "${expected}"
}

@test "a link spanning the break window moves intact to its own row" {
  local before= link= after= input= expected= nl=${codeNL}
  repeat_char before A 69
  repeat_char after B 1
  link="[label with spaces and more text](destination path with segments and additional filename)"
  input="${before} ${link} ${after}"
  expected="${before}${codeNL}${link}${codeNL}${after}${codeNL}"

  assert_wrapped "${input}" "${expected}"
}

@test "UTF-8 characters are counted as Bash characters" {
  local a79= text= expected= nl=${codeNL}
  repeat_char a79 A 79
  text="${a79}é X"
  expected="${a79}é${nl}X${nl}"
  assert_wrapped "${text}" "${expected}"
}
