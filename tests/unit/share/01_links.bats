#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../../../src/share/01_links.sh"
}

assert_spans() {
  local -a expected=("$@")
  local i

  if [[ ${#SHELL_MD_READI_LINK_SPANS[@]} -ne ${#expected[@]} ]]; then
    printf "expected %d spans, got %d: <%s>\n" \
      "${#expected[@]}" "${#SHELL_MD_READI_LINK_SPANS[@]}" \
      "${SHELL_MD_READI_LINK_SPANS[*]}" >&2
    return 1
  fi

  for ((i = 0; i < ${#expected[@]}; i++)); do
    if [[ ${SHELL_MD_READI_LINK_SPANS[i]} != "${expected[i]}" ]]; then
      printf "span %d: expected <%s>, got <%s>\n" \
        "$i" "${expected[i]}" "${SHELL_MD_READI_LINK_SPANS[i]}" >&2
      return 1
    fi
  done
}

@test "empty input clears the global register" {
  SHELL_MD_READI_LINK_SPANS=("stale:entry")

  shell_md_readi_link_spans

  assert_spans
}

@test "records multiple links and image links with zero-based half-open spans" {
  shell_md_readi_link_spans "see [one](a) and ![two](b)"

  assert_spans "4:12" "18:26"
}

@test "balances nested brackets and destination parentheses" {
  shell_md_readi_link_spans "[A [b]](file (1).md)"

  assert_spans "0:20"
}

@test "honors escaped closing brackets and parentheses inside a link" {
  shell_md_readi_link_spans "[\\]x](a\\)b)"

  assert_spans "0:11"
}

@test "skips an escaped opening bracket" {
  shell_md_readi_link_spans "\\[not](x)"

  assert_spans
}

@test "ignores bracketed text without a destination and incomplete links" {
  shell_md_readi_link_spans "[label] text and [open](dest"

  assert_spans
}

@test "returns success and resets prior spans when no link is found" {
  SHELL_MD_READI_LINK_SPANS=("8:14")

  shell_md_readi_link_spans "plain text"
  status=$?

  [[ $status -eq 0 ]]
  assert_spans
}
