#!/usr/bin/env bats

# Summary: Load the newline register and the function under test.
# Effects: Initializes the sourced global result register.
setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  . "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  . "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/03_headers.sh"
}

# Summary: Invoke the function and append sentinels to both output channels.
# Parameters: All arguments are forwarded to the function under test.
# Returns: The function status and one sentinel on each channel.
# Effects: Updates the result global in the Bats run subshell.
invoke_with_sentinels() {
  local rc=0
  shell_md_readi_canonize_headers "$@" || rc=${?}
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "${rc}"
}

# Summary: Check status, both channels, and exact result global.
# Parameters: $1 input and $2 expected output, using printf %b escapes.
# Returns: Zero on a match; otherwise nonzero with a mismatch diagnostic.
# Effects: Invokes the function twice and updates its result global.
assert_canonized() {
  local input=""
  local expected=""
  printf -v input "%b" "${1}"
  printf -v expected "%b" "${2}"
  run --separate-stderr invoke_with_sentinels "${input}"
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]] || return 1
  shell_md_readi_canonize_headers "${input}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_CANONIZE_HEADERS} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_CANONIZE_HEADERS}" >&2
    return 1
  fi
}

@test "empty input resets stale output to one newline" {
  SHELL_MD_READI_RESULT_CANONIZE_HEADERS=stale
  assert_canonized "" "\n"
}

@test "ordinary lines retain whitespace and end in a newline" {
  assert_canonized "  one  \n\ttwo\t" "  one  \n\ttwo\t\n"
}

@test "input trailing newlines add empty lines" {
  assert_canonized "x\n" "x\n\n"
  assert_canonized "x\n\n" "x\n\n\n"
}

@test "blank and whitespace-only lines remain distinct blank lines" {
  assert_canonized " \t\nx\n\t \n\ny" "\nx\n\n\ny\n"
}

@test "one or more equals convert the preceding text to H1" {
  assert_canonized "one\n=" "# one\n"
  assert_canonized "two\n====" "# two\n"
}

@test "one two three and four hyphens convert prose to H2" {
  assert_canonized "one\n-" "## one\n"
  assert_canonized "two\n--" "## two\n"
  assert_canonized "three\n---" "## three\n"
  assert_canonized "four\n----" "## four\n"
}

@test "underline trimming preserves title trailing whitespace" {
  assert_canonized " \tTitle  \n \t=== \t\n \tOther \t\n  ---  " "# Title  \n## Other \t\n"
}

@test "only the immediately preceding prose line becomes a heading" {
  assert_canonized "first\nsecond\n===\nthird\nfourth\n--" "first\n# second\nthird\n## fourth\n"
}

@test "underline without a pending text line remains ordinary content" {
  assert_canonized "=\n\n--" "=\n\n--\n"
  assert_canonized "text\n\n=" "text\n\n=\n"
}

@test "nonmatching underline markers do not become headings" {
  assert_canonized "title\n= =\nnext\n--x\nlast\n---x" "title\n= =\nnext\n--x\nlast\n---x\n"
}

@test "structural lines prevent long hyphens from becoming H2" {
  local line=""
  for line in "- item" "+ item" "* item" "> quote" "| cell" "<tag>" "1. item" "42) item" "&nbsp;" "    code"; do
    assert_canonized "${line}\n---" "${line}\n---\n" || return 1
  done
}

@test "numbered text without required space can become H2" {
  assert_canonized "1.title\n---" "## 1.title\n"
  assert_canonized "2)title\n---" "## 2)title\n"
}

@test "short hyphens and equals convert even structural pending text" {
  assert_canonized "- item\n--\n> quote\n=" "## - item\n# > quote\n"
}

@test "standalone separators normalize mixed markers and whitespace" {
  assert_canonized " * _ - \n\n___\n\n* * *" "---\n\n---\n\n---\n"
}

@test "separator minimum is three markers" {
  assert_canonized "**\n\n***\n\n****" "**\n\n---\n\n---\n"
}

@test "separator flushes text and consecutive separators independently" {
  assert_canonized "text\n***\n___\nend" "text\n---\n---\nend\n"
}

@test "separator is flushed at end or before blank ordinary and fenced lines" {
  local fence="\`\`\`"
  assert_canonized "***" "---\n"
  assert_canonized "***\n\nend" "---\n\nend\n"
  assert_canonized "***\nend" "---\nend\n"
  assert_canonized "***\n${fence}\n${fence}" "---\n${fence}\n${fence}\n"
}

@test "an ATX line preserves its original spacing and flushes prior text" {
  assert_canonized "text\n  ## heading  \nnext" "text\n  ## heading  \nnext\n"
}

@test "ATX immediately after a separator flushes that separator" {
  assert_canonized "***\n# title" "---\n# title\n"
}

@test "blank line prevents separator from being discarded by ATX" {
  assert_canonized "***\n\n# title" "---\n\n# title\n"
}

@test "fenced blocks protect headings separators and whitespace" {
  local fence="\`\`\`"
  assert_canonized "before\n  ${fence}bash\ntitle\n===\n * * * \n \t\n ${fence} end\nafter\n---" "before\n  ${fence}bash\ntitle\n===\n * * * \n \t\n ${fence} end\n## after\n"
}

@test "unclosed fence remains protected until end" {
  local fence="\`\`\`"
  assert_canonized "${fence}\ntitle\n---\n***" "${fence}\ntitle\n---\n***\n"
}

@test "fence flushes pending text and does not convert it using code content" {
  local fence="\`\`\`"
  assert_canonized "title\n${fence}\n===\n${fence}\nnext\n=" "title\n${fence}\n===\n${fence}\n# next\n"
}

@test "backticks away from trimmed line start do not toggle fence state" {
  local fence="\`\`\`"
  assert_canonized "text ${fence}\n=" "# text ${fence}\n"
}

@test "successive calls reset output and unclosed fence state" {
  local fence="\`\`\`"
  assert_canonized "${fence}\ntitle\n=" "${fence}\ntitle\n=\n"
  assert_canonized "title\n=" "# title\n"
  assert_canonized "" "\n"
}
