#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  source "${BATS_TEST_DIRNAME}/../../../../src/readi/format/01_compute_spacing.sh"
}

invoke_with_sentinels() {
  local rc=0
  shell_md_readi_format_compute_spacing "${@}" || rc=${?}
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "${rc}"
}

assert_spacing() {
  local expected=${1}
  shift
  run --separate-stderr invoke_with_sentinels "${@}"
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]] || return 1
  shell_md_readi_format_compute_spacing "${@}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING} != "${expected}" ]]; then
    printf "expected spacing %s, got %s\n" "${expected}" "${SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING}" >&2
    return 1
  fi
}

@test "defaults initialize the result and calculate ordinary spacing" {
  SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING=stale
  assert_spacing 0
  assert_spacing 1 "" OTHER OTHER
  assert_spacing 1 1 PARAGRAPH LIST
  [ "${SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING}" = 1 ]
}

@test "density tiers change at each exact threshold" {
  assert_spacing 1 1 OTHER OTHER
  assert_spacing 1 6 OTHER OTHER
  assert_spacing 2 7 OTHER OTHER
  assert_spacing 2 14 OTHER OTHER
  assert_spacing 3 15 OTHER OTHER
  assert_spacing 3 21 OTHER OTHER
  assert_spacing 4 22 OTHER OTHER
}

@test "end of document and hardbreak force zero spacing" {
  assert_spacing 0 22 PARAGRAPH
  assert_spacing 0 22 PARAGRAPH LIST 1 hardbreak
  assert_spacing 0 1 PARAGRAPH HEADER 1 hardbreak
  assert_spacing 1 22 LIST TABLE "" colon
}

@test "upstream header levels impose their minimum unless density is greater" {
  assert_spacing 5 1 PARAGRAPH HEADER 1
  assert_spacing 4 1 PARAGRAPH HEADER 2
  assert_spacing 3 1 PARAGRAPH HEADER 3
  assert_spacing 2 1 PARAGRAPH HEADER
  assert_spacing 2 1 PARAGRAPH HEADER 0
  assert_spacing 2 1 PARAGRAPH HEADER 4
  assert_spacing 2 1 PARAGRAPH HEADER 5
  assert_spacing 2 1 PARAGRAPH HEADER 6
  assert_spacing 2 1 PARAGRAPH HEADER 7
  assert_spacing 5 22 PARAGRAPH HEADER 1
  assert_spacing 4 22 PARAGRAPH HEADER 2
}

@test "paragraph adjacency caps density with header and paragraph exceptions" {
  assert_spacing 2 22 PARAGRAPH PARAGRAPH
  assert_spacing 2 15 PARAGRAPH PARAGRAPH
  assert_spacing 3 22 PARAGRAPH LIST
  assert_spacing 3 22 PARAGRAPH TABLE
  assert_spacing 4 22 PARAGRAPH HEADER 6
  assert_spacing 4 22 HEADER PARAGRAPH
}

@test "contiguous structural types have a two-line floor except quote pairs" {
  local types=(LIST TABLE CODE_BLOCK BLOCKQUOTE HTML_BLOCK) current next expected
  for current in "${types[@]}"; do
    for next in "${types[@]}"; do
      expected=2
      if [[ ${current} == BLOCKQUOTE && ${next} == BLOCKQUOTE ]]; then expected=1; fi
      assert_spacing "${expected}" 1 "${current}" "${next}" || return 1
    done
  done
  assert_spacing 4 22 BLOCKQUOTE BLOCKQUOTE
  assert_spacing 1 1 PARAGRAPH TABLE
  assert_spacing 1 1 LIST PARAGRAPH
}

@test "contiguous headers override density while other header transitions do not" {
  assert_spacing 1 1 HEADER HEADER
  assert_spacing 1 22 HEADER HEADER
  assert_spacing 4 22 HEADER PARAGRAPH
  assert_spacing 1 1 HEADER PARAGRAPH
}

@test "colon forces one line after other spacing rules and resets on the next call" {
  assert_spacing 1 22 LIST TABLE "" colon
  assert_spacing 1 22 PARAGRAPH HEADER 1 colon
  assert_spacing 1 22 PARAGRAPH PARAGRAPH "" colon
  assert_spacing 4 22 LIST TABLE
  [ "${SHELL_MD_READI_RESULT_FORMAT_COMPUTE_SPACING}" = 4 ]
}
