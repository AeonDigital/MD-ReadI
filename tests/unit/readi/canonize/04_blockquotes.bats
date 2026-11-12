#!/usr/bin/env bats

# Summary: Load the newline register and the function under test.
# Effects: Initializes the sourced global result register.
setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  . "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  . "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/04_blockquotes.sh"
}

# Summary: Invoke the function and append sentinels to both output channels.
# Parameters: All arguments are forwarded to the function under test.
# Returns: The function status and one sentinel on each channel.
# Effects: Updates the result global in the Bats run subshell.
invoke_with_sentinels() {
  local rc=0
  shell_md_readi_canonize_blockquotes "$@" || rc=${?}
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
  shell_md_readi_canonize_blockquotes "${input}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES}" >&2
    return 1
  fi
}

@test "empty input resets stale output to one newline" {
  SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES=stale
  assert_canonized "" "\n"
}

@test "missing argument behaves like empty input" {
  SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES=stale
  shell_md_readi_canonize_blockquotes
  [ "${SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES}" = $'\n' ]
}

@test "non-quote lines retain whitespace and end in a newline" {
  assert_canonized "  one  \n\ttwo\t\n\nthree a > b" "  one  \n\ttwo\t\n\nthree a > b\n"
}

@test "input trailing newlines add empty lines" {
  assert_canonized "x\n" "x\n\n"
  assert_canonized "x\n\n" "x\n\n\n"
}

@test "well formed quote line is unchanged" {
  assert_canonized "> text" "> text\n"
}

@test "missing space after marker is added" {
  assert_canonized ">text" "> text\n"
}

@test "several spaces or tabs after marker collapse to one space" {
  assert_canonized ">    text" "> text\n"
  assert_canonized ">\t\ttext" "> text\n"
}

@test "leading whitespace before marker is removed" {
  assert_canonized "   > text" "> text\n"
  assert_canonized "\t>text" "> text\n"
}

@test "empty quote lines become a lone marker" {
  assert_canonized ">" ">\n"
  assert_canonized "> " ">\n"
  assert_canonized ">  \t " ">\n"
  assert_canonized "  >" ">\n"
}

@test "trailing whitespace of quote prose is preserved" {
  assert_canonized ">  text  " "> text  \n"
}

@test "prose content is not rewritten" {
  assert_canonized "> **bold** \`code\` [l](u) # x" "> **bold** \`code\` [l](u) # x\n"
}

@test "marker characters inside the prose are kept" {
  assert_canonized "> a > b" "> a > b\n"
  assert_canonized "> > nested" "> > nested\n"
}

@test "stacked markers without spaces collapse to a single marker" {
  assert_canonized ">>text" "> text\n"
  assert_canonized ">> text" "> text\n"
  assert_canonized ">>>" ">\n"
}

@test "quote lines mixed with other lines keep order" {
  assert_canonized "before\n>a\n>\nafter\n\n>  b" "before\n> a\n>\nafter\n\n> b\n"
}

@test "fenced code block content is not changed" {
  assert_canonized "\`\`\`\n>text\n  >  x\n\`\`\`" "\`\`\`\n>text\n  >  x\n\`\`\`\n"
}

@test "indented fences open and close code blocks" {
  assert_canonized "  \`\`\`sh\n>a\n\t\`\`\`\n>b" "  \`\`\`sh\n>a\n\t\`\`\`\n> b\n"
}

@test "quotes before and after a code block are normalized" {
  assert_canonized ">a\n\`\`\`\n>b\n\`\`\`\n>c" "> a\n\`\`\`\n>b\n\`\`\`\n> c\n"
}

@test "unclosed code block leaves the remainder untouched" {
  assert_canonized ">a\n\`\`\`\n>b\n>c" "> a\n\`\`\`\n>b\n>c\n"
}

@test "fence marker inside a quote does not open a code block" {
  assert_canonized ">\`\`\`\n>a" "> \`\`\`\n> a\n"
}

@test "second code block reopens insulation after the first closes" {
  assert_canonized "\`\`\`\n\`\`\`\n>a\n\`\`\`\n>b\n\`\`\`" "\`\`\`\n\`\`\`\n> a\n\`\`\`\n>b\n\`\`\`\n"
}

@test "result register is reset between calls" {
  shell_md_readi_canonize_blockquotes ">a"
  shell_md_readi_canonize_blockquotes "b"
  [ "${SHELL_MD_READI_RESULT_CANONIZE_BLOCKQUOTES}" = $'b\n' ]
}
