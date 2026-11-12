#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  source "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  source "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/02_blank_lines.sh"
}

# Preserve trailing newlines in both channels when Bats captures output.
invoke_with_sentinels() {
  local rc
  if shell_md_readi_canonize_blank_lines "$@"; then rc=0; else rc=$?; fi
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "$rc"
}

# Expand readable strings without losing trailing newlines. Bats run isolates
# globals, so also call the function directly to inspect its result register.
assert_canonized() {
  local input expected
  printf -v input "%b" "$1"
  printf -v expected "%b" "$2"
  run --separate-stderr invoke_with_sentinels "$input"
  [[ $status -eq 0 && $output == stdout-sentinel && $stderr == stderr-sentinel ]] || return 1
  if shell_md_readi_canonize_blank_lines "$input"; then :; else return 1; fi
  if [[ $SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES != "$expected" ]]; then
    printf "expected %q, got %q\n" "$expected" "$SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES" >&2
    return 1
  fi
}

@test "empty input replaces stale global with one newline" {
  SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES=stale
  assert_canonized "" "\n"
}

@test "omitted input replaces stale global with one newline" {
  SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES=stale
  run --separate-stderr invoke_with_sentinels
  [[ $status -eq 0 && $output == stdout-sentinel && $stderr == stderr-sentinel ]]
  if shell_md_readi_canonize_blank_lines; then :; else return 1; fi
  [[ $SHELL_MD_READI_RESULT_CANONIZE_BLANK_LINES == "$codeNL" ]]
}

@test "content is preserved and terminated by a newline" {
  assert_canonized "  one  \n\ttwo\t" "  one  \n\ttwo\t\n"
}

@test "an input final newline produces an additional blank line" {
  assert_canonized "text\n" "text\n\n"
}

@test "one or many empty lines compress between content" {
  assert_canonized "a\n\nb" "a\n\nb\n"
  assert_canonized "a\n\n\n\n\nb" "a\n\nb\n"
}

@test "whitespace only lines compress together" {
  assert_canonized "a\n \t\n\r\n\tb" "a\n\n\tb\n"
}

@test "leading and trailing runs of empty lines compress separately" {
  assert_canonized "\n\na\n\n\n" "\na\n\n"
}

@test "empty lines alone compress to one newline" {
  assert_canonized "\n\n\n" "\n"
}

@test "isolated nbsp emits zero edge counts" {
  assert_canonized "&nbsp;" "&nbsp; 0/1/0\n"
}

@test "nbsp at the beginning counts trailing blanks" {
  assert_canonized "&nbsp;\n\ntext" "&nbsp; 0/1/1\ntext\n"
}

@test "nbsp at the end counts preceding blanks" {
  assert_canonized "text\n\n&nbsp;" "text\n&nbsp; 1/1/0\n"
}

@test "final newline after nbsp is counted as trailing blank" {
  assert_canonized "&nbsp;\n" "&nbsp; 0/1/1\n"
}

@test "spaced nbsp and whitespace are trimmed only for recognition" {
  assert_canonized "before\n \t\n  &nbsp; \t\n\t \nafter" "before\n&nbsp; 1/1/1\nafter\n"
}

@test "adjacent nbsp tokens accumulate without a cap" {
  assert_canonized "&nbsp;\n&nbsp;\n&nbsp;\n&nbsp;" "&nbsp; 0/4/0\n"
}

@test "blank lines before and after repeated nbsp tokens are counted" {
  assert_canonized "a\n\n&nbsp;\n&nbsp;\n\n\nb" "a\n&nbsp; 1/2/2\nb\n"
}

@test "blank lines between nbsp tokens contribute to trailing count" {
  assert_canonized "&nbsp;\n\n&nbsp;\n\ntext" "&nbsp; 0/2/2\ntext\n"
}

@test "separated nbsp groups are encoded independently" {
  assert_canonized "&nbsp;\ntext\n&nbsp;" "&nbsp; 0/1/0\ntext\n&nbsp; 0/1/0\n"
}

@test "leading count covers values immediately below at and above cap" {
  assert_canonized "x\n\n\n&nbsp;\ny" "x\n&nbsp; 2/1/0\ny\n"
  assert_canonized "x\n\n\n\n&nbsp;\ny" "x\n&nbsp; 3/1/0\ny\n"
  assert_canonized "x\n\n\n\n\n&nbsp;\ny" "x\n&nbsp; 3/1/0\ny\n"
}

@test "trailing count covers values immediately below at and above cap" {
  assert_canonized "x\n&nbsp;\n\n\ny" "x\n&nbsp; 0/1/2\ny\n"
  assert_canonized "x\n&nbsp;\n\n\n\ny" "x\n&nbsp; 0/1/3\ny\n"
  assert_canonized "x\n&nbsp;\n\n\n\n\ny" "x\n&nbsp; 0/1/3\ny\n"
}

@test "both edge counts cap independently" {
  assert_canonized "x\n\n\n\n\n&nbsp;\n\n\n\n\ny" "x\n&nbsp; 3/1/3\ny\n"
}

@test "nonexact nbsp and existing metadata are ordinary content" {
  assert_canonized "x&nbsp;\n&nbsp; text\n&nbsp; 1/2/3\n&nbsp" "x&nbsp;\n&nbsp; text\n&nbsp; 1/2/3\n&nbsp\n"
}

@test "closed fenced code retains blank lines and literal nbsp" {
  assert_canonized "before\n\`\`\`bash\n\n\n&nbsp;\n \t\n\`\`\`\nafter" "before\n\`\`\`bash\n\n\n&nbsp;\n \t\n\`\`\`\nafter\n"
}

@test "unclosed fenced code remains untouched through end of input" {
  assert_canonized "\`\`\`\n&nbsp;\n\n\nend" "\`\`\`\n&nbsp;\n\n\nend\n"
}

@test "trimmed fences preserve original indentation and toggle protection" {
  assert_canonized "  \`\`\` lang \n\n&nbsp;\n \t\`\`\` end\n&nbsp;" "  \`\`\` lang \n\n&nbsp;\n \t\`\`\` end\n&nbsp; 0/1/0\n"
}

@test "blank and nbsp scanning stops at fences and resumes after closing" {
  assert_canonized "a\n\n&nbsp;\n\n\`\`\`\n\n\`\`\`\n\n&nbsp;\n\nb" "a\n&nbsp; 1/1/1\n\`\`\`\n\n\`\`\`\n&nbsp; 1/1/1\nb\n"
}

@test "backticks not at trimmed start do not open a fence" {
  assert_canonized "x \`\`\`\n&nbsp;\n\nend" "x \`\`\`\n&nbsp; 0/1/1\nend\n"
}

@test "successive calls reset all parsing state and replace output" {
  assert_canonized "\`\`\`\n&nbsp;" "\`\`\`\n&nbsp;\n"
  assert_canonized "&nbsp;" "&nbsp; 0/1/0\n"
  assert_canonized "" "\n"
}
