#!/usr/bin/env bats

# Summary: Load the newline register, real dependency and function under test.
# Effects: Initializes the global result registers and mock call log.
setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  . "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  . "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/07_indentation_block.sh"
  . "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/08_indentation.sh"
  MOCK_BLOCKS=()
}

# Summary: Replace block normalization with a traceable deterministic result.
# Parameters: $1 is the exact block passed by the stream parser.
# Returns: Zero.
# Effects: Records the argument and updates the block result register.
mock_blocks() {
  shell_md_readi_canonize_indentation_block() {
    MOCK_BLOCKS+=("${1}")
    SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK="[${1}]"
  }
}

# Summary: Invoke the parser with a sentinel on each output channel.
# Parameters: All arguments are forwarded to the parser.
# Returns: Parser status with sentinels on stdout and stderr.
# Effects: Updates parser and mock globals in the Bats run subshell.
invoke_with_sentinels() {
  local rc=0
  shell_md_readi_canonize_indentation "${@}" || rc=${?}
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "${rc}"
}

# Summary: Check the result register, status and both output channels.
# Parameters: $1 input and $2 expected result, encoded using printf %b.
# Returns: Zero on a match, otherwise nonzero with a diagnostic.
# Effects: Invokes the parser twice and updates its result register.
assert_indentation() {
  local input=""
  local expected=""
  printf -v input "%b" "${1}"
  printf -v expected "%b" "${2}"
  run --separate-stderr invoke_with_sentinels "${input}"
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]] || return 1
  shell_md_readi_canonize_indentation "${input}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION}" >&2
    return 1
  fi
}

@test "empty input and omitted input clear stale state without calling the block helper" {
  mock_blocks
  SHELL_MD_READI_RESULT_CANONIZE_INDENTATION=stale
  assert_indentation "" "\n"
  [ "${#MOCK_BLOCKS[@]}" -eq 0 ]
  SHELL_MD_READI_RESULT_CANONIZE_INDENTATION=stale
  run --separate-stderr invoke_with_sentinels
  [ "${status}" -eq 0 ]
  [ "${output}" = stdout-sentinel ]
  [ "${stderr}" = stderr-sentinel ]
  shell_md_readi_canonize_indentation
  [ "${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION}" = "${codeNL}" ]
  [ "${#MOCK_BLOCKS[@]}" -eq 0 ]
}

@test "adjacent lines form one exact block with no final separator" {
  mock_blocks
  assert_indentation "one  \n  two\\\\path\t" "[one  \n  two\\\\path\t]"
  [ "${#MOCK_BLOCKS[@]}" -eq 1 ]
  [ "${MOCK_BLOCKS[0]}" = "$(printf "one  \n  two\\\\path\t")" ]
}

@test "empty lines split blocks while whitespace only lines remain inside" {
  mock_blocks
  assert_indentation "\nfirst\n \n\t\nnext\n\n\nlast" "\n[first\n \n\t\nnext]\n\n[last]"
  [ "${#MOCK_BLOCKS[@]}" -eq 2 ]
  [ "${MOCK_BLOCKS[1]}" = last ]
}

@test "zero one and two trailing newlines are distinct boundaries" {
  mock_blocks
  assert_indentation "x" "[x]"
  assert_indentation "x\n" "[x]\n"
  assert_indentation "x\n\n" "[x]\n\n"
}

@test "opening and closing fences flush blocks and preserve code verbatim" {
  mock_blocks
  assert_indentation "before\n  \`\`\`sh\n  code\n\n\tline\n\t\`\`\`end\nafter" "[before]\n  \`\`\`sh\n  code\n\n\tline\n\t\`\`\`end\n[after]"
  [ "${#MOCK_BLOCKS[@]}" -eq 2 ]
  [ "${MOCK_BLOCKS[0]}" = before ]
  [ "${MOCK_BLOCKS[1]}" = after ]
}

@test "unclosed fences protect the remainder and state resets between calls" {
  mock_blocks
  assert_indentation "\`\`\`\n  x\n\n  y" "\`\`\`\n  x\n\n  y\n"
  [ "${#MOCK_BLOCKS[@]}" -eq 0 ]
  SHELL_MD_READI_RESULT_CANONIZE_INDENTATION=stale
  assert_indentation "next" "[next]"
  [ "${#MOCK_BLOCKS[@]}" -eq 1 ]
}

@test "adjacent and multiple fences toggle protection without empty helper calls" {
  mock_blocks
  assert_indentation "\`\`\`\n\`\`\`\nmid\n\`\`\`more\nx\n\`\`\`\nend" "\`\`\`\n\`\`\`\n[mid]\n\`\`\`more\nx\n\`\`\`\n[end]"
  [ "${#MOCK_BLOCKS[@]}" -eq 2 ]
}

@test "two backticks tildes and nonleading backticks do not open fences" {
  mock_blocks
  assert_indentation "\`\`\n~~~\ntext \`\`\`\n  content" "[\`\`\n~~~\ntext \`\`\`\n  content]"
  [ "${#MOCK_BLOCKS[@]}" -eq 1 ]
}

@test "caller IFS is preserved with block parsing and fences" {
  mock_blocks
  IFS=":"
  assert_indentation "a\n b\n\n\`\`\`\nx\n\`\`\`" "[a\n b]\n\`\`\`\nx\n\`\`\`\n"
  [ "${IFS}" = ":" ]
}

@test "configured newline register controls output separators" {
  run --separate-stderr bash -c "codeNL=\"|\"; . \"\${1}\"; . \"\${2}\"; shell_md_readi_canonize_indentation_block() { SHELL_MD_READI_RESULT_CANONIZE_INDENTATION_BLOCK=\"[\${1}]\"; }; shell_md_readi_canonize_indentation \"a\"; printf \"%s\" \"\${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION}\"" _ "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh" "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/08_indentation.sh"
  [ "${status}" -eq 0 ]
  [ "${output}" = "[a]" ]
  [ -z "${stderr}" ]
  run --separate-stderr bash -c "codeNL=\"|\"; . \"\${1}\"; . \"\${2}\"; shell_md_readi_canonize_indentation \"\"; printf \"%s\" \"\${SHELL_MD_READI_RESULT_CANONIZE_INDENTATION}\"" _ "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh" "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/08_indentation.sh"
  [ "${status}" -eq 0 ]
  [ "${output}" = "|" ]
  [ -z "${stderr}" ]
}

@test "real helper normalizes independent blocks without adding blank lines" {
  assert_indentation "root\n  child\n\nsecond\n    child" "root\n\tchild\n\nsecond\n\tchild\n"
}

@test "real helper preserves preformatted blocks in the register without output" {
  assert_indentation "    code\n    next" "    code\n    next\n"
}

@test "real helper bypasses fenced preformatted content and normalizes following text" {
  assert_indentation "\`\`\`\n    code\n\`\`\`\nroot\n  child" "\`\`\`\n    code\n\`\`\`\nroot\n\tchild\n"
}
