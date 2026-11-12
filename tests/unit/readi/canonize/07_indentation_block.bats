#!/usr/bin/env bats


# Summary: Load the newline register and the function under test.
# Effects: Initializes the global result register.
setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  . "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  . "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/07_indentation_block.sh"
}

# Summary: Invoke the function with a sentinel on each output channel.
# Parameters: All arguments are forwarded to the function.
# Returns: The function status and a sentinel on each channel.
# Effects: Updates the result global in the Bats run subshell.
invoke_with_sentinels() {
  local rc=0
  shell_md_readi_canonize_indentation_block "${@}" || rc=${?}
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "${rc}"
}

# Summary: Check status, both channels and the exact result register.
# Parameters: $1 input and $2 expected output, using printf %b escapes.
# Returns: Zero on a match, otherwise nonzero with a diagnostic.
# Effects: Calls the function twice and updates the result global.
assert_block() {
  local input=""
  local expected=""
  printf -v input "%b" "${1}"
  printf -v expected "%b" "${2}"
  run --separate-stderr invoke_with_sentinels "${input}"
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]] || return 1
  shell_md_readi_canonize_indentation_block "${input}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK}" >&2
    return 1
  fi
}

@test "plain lines and trailing whitespace remain unchanged" {
  assert_block "first  \nsecond\t\nthird" "first  \nsecond\t\nthird\n"
}

@test "leading middle and trailing blank lines are retained" {
  assert_block "\nplain\n\nend\n" "\nplain\n\nend\n\n"
  assert_block "plain\n\n" "plain\n\n\n"
}

@test "space levels are ranked numerically regardless of encounter order" {
  assert_block "root\n     five\n one\n   three\n     again\n  two" "root\n\t\t\t\tfive\n\tone\n\t\t\tthree\n\t\t\t\tagain\n\t\ttwo\n"
}

@test "multi digit space levels use numeric rather than lexical sorting" {
  assert_block "root\n          ten\n  two\n         nine" "root\n\t\t\tten\n\ttwo\n\t\tnine\n"
}

@test "one space level maps to one tab independent of its width" {
  assert_block "root\n x\n y" "root\n\tx\n\ty\n"
  assert_block "root\n        x" "root\n\tx\n"
}

@test "three four and five spaces normalize when the block is not preformatted" {
  assert_block "root\n   three\n    four\n     five" "root\n\tthree\n\t\tfour\n\t\t\tfive\n"
}

@test "tabs anywhere in an indented prefix select preservation for the whole block" {
  assert_block "root\n  spaces\n\ttab\n    later" "root\n  spaces\n\ttab\n    later\n"
  assert_block "root\n \tmixed\n  spaces" "root\n \tmixed\n  spaces\n"
}

@test "tabs inside content or on whitespace only lines do not select tab mode" {
  assert_block "root\n one\ttext\n\t\n  two" "root\n\tone\ttext\n\t\n\t\ttwo\n"
}

@test "whitespace only lines remain intact and do not add levels" {
  assert_block "root\n     \n x\n  \n   y" "root\n     \n\tx\n  \n\t\ty\n"
}

@test "backslashes punctuation and multibyte body text are preserved" {
  assert_block "root\n  path\\\\file \u00e9 !\n x" "root\n\t\tpath\\\\file \u00e9 !\n\tx\n"
}

@test "four spaces followed by a tab or extra space are not preformatted" {
  assert_block "    \tx" "    \tx\n"
  assert_block "     x" "\tx\n"
}

@test "four spaces alone are not preformatted and remain unchanged" {
  assert_block "    " "    \n"
}

@test "a whitespace only line disqualifies an otherwise preformatted block" {
  assert_block "    code\n " "\tcode\n \n"
}

@test "a nonempty unindented line disqualifies an otherwise preformatted block" {
  assert_block "    code\ntext" "\tcode\ntext\n"
}

@test "ordinary calls replace stale output without retaining indentation levels" {
  SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK=stale
  assert_block "root\n a\n  b" "root\n\ta\n\t\tb\n"
  assert_block "root\n  c" "root\n\tc\n"
}

@test "IFS is unchanged after sorting and processing" {
  local input=""
  printf -v input "%b" "root\n   x\n y"
  IFS=":"
  shell_md_readi_canonize_indentation_block "${input}"
  [ "${IFS}" = ":" ]
}

@test "space level ranking is independent of the caller IFS" {
  IFS=":"
  assert_block "root\n   x\n y" "root\n\t\tx\n\ty\n"
}

@test "preformatted block publishes preserved content through the result register" {
  local input=""
  local expected=""
  printf -v input "%b" "    code\n\n    next"
  printf -v expected "%b" "    code\n\n    next\n"
  SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK=stale
  shell_md_readi_canonize_indentation_block "${input}"
  [ "${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK}" = "${expected}" ]
}

@test "preformatted block returns success without emitting either channel" {
  local input=""
  printf -v input "%b" "    code\n\n    next"
  run --separate-stderr invoke_with_sentinels "${input}"
  [ "${status}" -eq 0 ]
  [ "${output}" = stdout-sentinel ]
  [ "${stderr}" = stderr-sentinel ]
}

@test "empty input publishes one newline through the result register" {
  SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK=stale
  shell_md_readi_canonize_indentation_block ""
  [ "${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK}" = "${codeNL}" ]
}

@test "empty input returns success without emitting either channel" {
  run --separate-stderr invoke_with_sentinels ""
  [ "${status}" -eq 0 ]
  [ "${output}" = stdout-sentinel ]
  [ "${stderr}" = stderr-sentinel ]
}

@test "omitted input has the same result and channels as empty input" {
  SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK=stale
  run --separate-stderr invoke_with_sentinels
  [ "${status}" -eq 0 ]
  [ "${output}" = stdout-sentinel ]
  [ "${stderr}" = stderr-sentinel ]
  shell_md_readi_canonize_indentation_block
  [ "${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK}" = "${codeNL}" ]
}
