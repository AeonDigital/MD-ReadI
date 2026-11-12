#!/usr/bin/env bats

# Summary:
# - Prepare the character canonization tests.
#
# Description:
# - Set the locale and load the function under test.
setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  . "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/01_characters.sh"
}

# Summary:
# - Check the character canonization result.
#
# Description:
# - Verify status, output channels, and the result global.
#
# Parameters:
# - $1 [string]: Input text to canonize.
# - $2 [string]: Expected canonized text.
#
# Returns:
# - status: 0 if all checks pass; 1 if a check fails.
# - stdout: None on successful canonization.
# - stderr: A mismatch diagnostic, or a diagnostic from canonization on failure.
# - global state: Sets SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS on direct call;
#   Bats run also updates its capture variables.
#
# Effects:
# - Calls canonization through Bats run and again in the current shell.
assert_canonized() {
  local input=${1}
  local expected=${2}
  run --separate-stderr shell_md_readi_canonize_characters "${input}"
  [[ ${status} -eq 0 && -z ${output} && -z ${stderr} ]] || return 1
  shell_md_readi_canonize_characters "${input}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS}" >&2
    return 1
  fi
}

@test "empty input resets a stale result and emits nothing" {
  SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS=stale
  assert_canonized "" ""
}

@test "omitted input resets a stale result and emits nothing" {
  SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS=stale
  run --separate-stderr shell_md_readi_canonize_characters
  [[ ${status} -eq 0 && -z ${output} && -z ${stderr} ]] || return 1
  if shell_md_readi_canonize_characters; then :; else return 1; fi
  [[ -z ${SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS} ]]
}

@test "ordinary ASCII and non-target Unicode are preserved" {
  assert_canonized $'Hello, caf\u00e9 \u4e16\u754c \u2014 \u2026' $'Hello, caf\u00e9 \u4e16\u754c \u2014 \u2026'
}

@test "all representable excluded ASCII control bytes and DEL are removed" {
  local n=0
  local octal=""
  local byte=""
  local input=""
  local expected=""
  for ((n = 1; n <= 127; n++)); do
    if ((n > 31 && n != 127)); then continue; fi
    printf -v octal "%03o" "${n}"
    printf -v byte "%b" "\\${octal}"
    input+="A${byte}B"
    if ((n == 9 || n == 10 || n == 13)); then
      expected+="A${byte}B"
    else
      expected+="AB"
    fi
  done
  assert_canonized "${input}" "${expected}"
}

@test "tabs carriage returns and internal newlines are retained" {
  assert_canonized $'a\tb\rc\nd' $'a\tb\rc\nd'
}

@test "trailing newlines are retained" {
  assert_canonized $'a\n\n' $'a\n\n'
  assert_canonized $'\n' $'\n'
}

@test "all curved quote variants normalize to ASCII" {
  assert_canonized $'\u201cone\u201d \u2018two\u2019 \u201cthree\u2018four\u2019\u201d' "\"one\" 'two' \"three'four'\""
}

@test "zero width spaces are removed at the start middle and end" {
  local marker=$'\u200b'
  assert_canonized "${marker}a${marker}b${marker}" "ab"
}

@test "UTF-8 byte order marks are removed at the start middle and end" {
  local marker=$'\ufeff'
  assert_canonized "${marker}a${marker}b${marker}" "ab"
}

@test "text resembling escape notation remains ordinary text" {
  local text="\$'\\u200b' and \$'\\uefbbbf'"
  assert_canonized "${text}" "${text}"
}

@test "successive calls replace rather than accumulate global output" {
  assert_canonized $'\u201cfirst\u201d' '"first"'
  assert_canonized "second" "second"
  assert_canonized "" ""
}

@test "tr failure preserves its diagnostic and stores normalized partial output" {
  # Summary:
  # - Invoke canonization with a failing tr mock.
  #
  # Description:
  # - Check the global and add channel sentinels to retain trailing newlines.
  #
  # Parameters:
  # - $1 [string]: Input text passed to canonization.
  #
  # Returns:
  # - status: 0 on success; canonization status on failure; 90 on mismatch.
  # - stdout: The stdout sentinel after a successful global check.
  # - stderr: The mock diagnostic and, after success, the stderr sentinel.
  # - global state: Resets and sets SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS.
  #
  # Effects:
  # - Defines a tr mock, invokes canonization, and writes channel sentinels.
  canonize_with_failed_tr() {
    # Summary:
    # - Simulate a tr failure after producing partial output.
    #
    # Description:
    # - Emit a diagnostic and partial text with a quote and trailing newline.
    #
    # Parameters:
    # - All arguments are ignored; standard input is not read.
    #
    # Returns:
    # - status: 42.
    # - stdout: Partial text with curved quotes and a trailing newline.
    # - stderr: The mock failure diagnostic and a trailing newline.
    # - global state: Unchanged.
    #
    # Effects:
    # - Writes simulated output and a diagnostic without invoking external tr.
    tr() {
      printf "%s" $'\u201cpartial\u201d\n'
      printf "mock tr failure\n" >&2
      return 42
    }

    SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS=stale
    shell_md_readi_canonize_characters "${1}" || return ${?}
    [[ ${SHELL_MD_READI_RESULT_CANONIZE_CHARACTERS} == $'"partial"\n' ]] || return 90
    printf "%s" "stdout-sentinel"
    printf "%s" "stderr-sentinel" >&2
  }

  run --separate-stderr canonize_with_failed_tr "input"
  [[ ${status} -eq 0 ]]
  [[ ${output} == "stdout-sentinel" ]]
  [[ ${stderr} == $'mock tr failure\nstderr-sentinel' ]]
}
