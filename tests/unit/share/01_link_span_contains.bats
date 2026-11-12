#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  source "${BATS_TEST_DIRNAME}/../../../src/share/01_links.sh"
}

assert_contains_status() {
  local expected=$1
  shift

  run --separate-stderr shell_md_readi_link_span_contains "$@"
  [[ $status -eq $expected ]]
  [[ -z $output ]]
  [[ -z $stderr ]]
}

@test "empty register rejects an index and the default index" {
  SHELL_MD_READI_LINK_SPANS=()

  assert_contains_status 1 0
  assert_contains_status 1
}

@test "span bounds are inclusive at start and exclusive at end" {
  SHELL_MD_READI_LINK_SPANS=("4:8")

  assert_contains_status 1 3
  assert_contains_status 0 4
  assert_contains_status 0 5
  assert_contains_status 0 7
  assert_contains_status 1 8
  assert_contains_status 1 9
}

@test "zero start includes zero and rejects a negative index" {
  SHELL_MD_READI_LINK_SPANS=("0:1")

  assert_contains_status 1 -1
  assert_contains_status 0 0
  assert_contains_status 1 1
}

@test "searches all spans and rejects indices in gaps" {
  SHELL_MD_READI_LINK_SPANS=("7:9" "2:4" "12:14")

  assert_contains_status 0 7
  assert_contains_status 0 2
  assert_contains_status 0 13
  assert_contains_status 1 4
  assert_contains_status 1 10
  assert_contains_status 1 14
}

@test "overlapping and empty spans do not hide a later match" {
  SHELL_MD_READI_LINK_SPANS=("3:3" "4:7" "6:9")

  assert_contains_status 1 3
  assert_contains_status 0 6
  assert_contains_status 0 8
  assert_contains_status 1 9
}

@test "omitted or empty index defaults to zero" {
  SHELL_MD_READI_LINK_SPANS=("0:1")

  assert_contains_status 0
  assert_contains_status 0 ""
  SHELL_MD_READI_LINK_SPANS=("1:2")
  assert_contains_status 1
  assert_contains_status 1 ""
}

@test "successful and unsuccessful checks leave the register unchanged" {
  SHELL_MD_READI_LINK_SPANS=("2:4" "7:9")
  local before
  before=$(declare -p SHELL_MD_READI_LINK_SPANS)

  shell_md_readi_link_span_contains 3
  [[ $(declare -p SHELL_MD_READI_LINK_SPANS) == "$before" ]]

  if shell_md_readi_link_span_contains 4; then
    return 1
  fi
  [[ $(declare -p SHELL_MD_READI_LINK_SPANS) == "$before" ]]
}
