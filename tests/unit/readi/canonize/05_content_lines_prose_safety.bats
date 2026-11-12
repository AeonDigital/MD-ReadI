#!/usr/bin/env bats

# Summary: Load the real link scanner and the function under test.
# Effects: Initializes the sourced global registers.
setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  . "${BATS_TEST_DIRNAME}/../../../../src/share/01_links.sh"
  . "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/05_content_lines.sh"
}

# Summary: Invoke the function with a sentinel on each output channel.
# Parameters: All arguments are forwarded to the function under test.
# Returns: The function status and a sentinel on each channel.
# Effects: Updates globals in the Bats run subshell.
invoke_with_sentinels() {
  local rc=0
  _shell_md_readi_canonize_prose_safety "${@}" || rc=${?}
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "${rc}"
}

# Summary: Check status, both output channels, and the exact result register.
# Parameters: $1 input and $2 expected output, using printf %b escapes.
# Returns: Zero on a match; otherwise nonzero with a diagnostic.
# Effects: Invokes the function twice and updates its global registers.
assert_prose() {
  local input=""
  local expected=""
  printf -v input "%b" "${1}"
  printf -v expected "%b" "${2}"
  run --separate-stderr invoke_with_sentinels "${input}"
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]] || return 1
  _shell_md_readi_canonize_prose_safety "${input}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}" >&2
    return 1
  fi
}

@test "empty and omitted input reset stale result and emit nothing" {
  SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY=stale
  assert_prose "" ""
  SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY=stale
  run --separate-stderr invoke_with_sentinels
  [ "${status}" -eq 0 ]
  [ "${output}" = stdout-sentinel ]
  [ "${stderr}" = stderr-sentinel ]
  _shell_md_readi_canonize_prose_safety
  [ "${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}" = "" ]
}

@test "plain and whitespace only inputs are preserved" {
  assert_prose "plain text  " "plain text  "
  assert_prose "  \t\n " "  \t\n "
}

@test "each standalone punctuation becomes its Unicode equivalent" {
  assert_prose "a - b" "a \u2014 b"
  assert_prose "a + b" "a \uff0b b"
  assert_prose "a * b" "a \u2217 b"
  assert_prose "a - b + c * d" "a \u2014 b \uff0b c \u2217 d"
}

@test "multiple spaces are preserved around converted symbols" {
  assert_prose "a  -  b  +  c  *  d" "a  \u2014  b  \uff0b  c  \u2217  d"
}

@test "symbols without a literal space on either side are unchanged" {
  assert_prose "- a" "- a"
  assert_prose "a -" "a -"
  assert_prose "+ a" "+ a"
  assert_prose "a +" "a +"
  assert_prose "* a" "* a"
  assert_prose "a *" "a *"
  assert_prose "a-b a+b a*b a -b a- b" "a-b a+b a*b a -b a- b"
  assert_prose "a\t- b a -\tb a\n+ b a +\nb" "a\t- b a -\tb a\n+ b a +\nb"
}

@test "leading indentation is retained and excluded from translation" {
  assert_prose "  \t- text" "  \t- text"
  assert_prose " \ttext - end" " \ttext \u2014 end"
  assert_prose "  - " "  - "
}

@test "trailing space enables conversion at the end of prose" {
  assert_prose "text - " "text \u2014 "
  assert_prose "text + " "text \uff0b "
  assert_prose "text * " "text \u2217 "
}

@test "repeated hyphens sharing a boundary are all converted" {
  assert_prose "a - - b" "a \u2014 \u2014 b"
}

@test "repeated plus signs sharing a boundary are all converted" {
  assert_prose "a + + b" "a \uff0b \uff0b b"
}

@test "repeated asterisks sharing a boundary are all converted" {
  assert_prose "a * * b" "a \u2217 \u2217 b"
}

@test "links protect both label and destination while surrounding prose changes" {
  assert_prose "a - [x + y](p - q) + z" "a \u2014 [x + y](p - q) \uff0b z"
  assert_prose "[a - b](x + y)" "[a - b](x + y)"
}

@test "multiple adjacent and separated links are copied independently" {
  assert_prose "[a - b](x)[c + d](y) - [e * f](z) + tail" "[a - b](x)[c + d](y) \u2014 [e * f](z) \uff0b tail"
}

@test "nested escaped and image links remain atomic" {
  assert_prose "![a - [b + c]](x (y * z)) - end" "![a - [b + c]](x (y * z)) \u2014 end"
  assert_prose "[a\\] - b](x\\) + y) * end" "[a\\] - b](x\\) + y) \u2217 end"
}

@test "malformed or escaped link openings do not protect prose" {
  assert_prose "[a - b](unfinished" "[a \u2014 b](unfinished"
  assert_prose "\\[a + b](x)" "\\[a \uff0b b](x)"
}

@test "multibyte prefixes and indentation do not shift link boundaries" {
  assert_prose " \t\u00e9 - [x + y](z) * \u00f8" " \t\u00e9 \u2014 [x + y](z) \u2217 \u00f8"
}

@test "successive calls replace the result and clear stale link spans" {
  SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES=untouched
  _shell_md_readi_canonize_prose_safety "[x](y) - z"
  [ "${#SHELL_MD_READI_LINK_SPANS[@]}" -eq 1 ]
  _shell_md_readi_canonize_prose_safety "plain"
  [ "${SHELL_MD_READI_RESULT_CANONIZE_PROSE_SAFETY}" = plain ]
  [ "${#SHELL_MD_READI_LINK_SPANS[@]}" -eq 0 ]
  [ "${SHELL_MD_READI_RESULT_CANONIZE_CONTENT_LINES}" = untouched ]
}

# Summary: Record the stripped input and return one controlled atomic span.
# Parameters: $1 input supplied by the function under test.
# Returns: Zero with the configured half-open span.
# Effects: Updates the mock capture and link span globals.
mock_single_span() {
  MOCK_SCANNED_INPUT="${1}"
  SHELL_MD_READI_LINK_SPANS=("4:11")
  return 0
}

@test "scanner receives unindented text and its spans control insulation" {
  local MOCK_SCANNED_INPUT=""
  shell_md_readi_link_spans() { mock_single_span "${@}"; }
  assert_prose "  a - [x + y] * b" "  a \u2014 [x + y] \u2217 b"
  [ "${MOCK_SCANNED_INPUT}" = "a - [x + y] * b" ]
  [ "${SHELL_MD_READI_LINK_SPANS[0]}" = "4:11" ]
}
