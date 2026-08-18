MD-ReadI - Specification
================================

> Universal structural formatting specification for human-centric Markdown text.

&nbsp;

This document establishes the universal structural formatting rules for writing and
maintaining high-quality Markdown (.md) documentation. The absolute driving principle
is "Human Readability First". Documents must be designed to be comfortably scanned
and read by human eyes directly in their raw text or code editor format, without
relying on HTML rendering engines.

Furthermore, this specification serves as a behavioral baseline for both human authors
and Artificial Intelligence agents to programmatically generate clean, accessible,
and universally standardized technical text.

This specification is implementation-oriented by design. Its rules are intended to
be encoded in a formatting/parsing software artifact that applies them automatically
during authoring workflows or post-edit normalization, minimizing manual burden on
authors.

Unless explicitly stated otherwise, normative statements in this document define
the expected output state of a conforming implementation.




&nbsp;
________________________________________________________________________________

## 1. ENCODING RULES

### 1.1 Strict Encoding Directives & Legacy Terminal Compatibility

All documentation files must be natively encoded in UTF-8 format strictly without
a Byte Order Mark (BOM).

All visible UTF-8 characters are permitted by default.

For baseline compatibility with legacy terminal architectures and maximal visual
predictability, authors are strongly encouraged to prioritize standard US-ASCII characters
in prose.

The Unicode Box-Drawing Characters block (U+2500 through U+257F) is explicitly encouraged
for visual tree directory structures and operational flowcharts in raw text files.

Additional non-ASCII visible characters may be used when technical precision or domain
context requires them. This specification defines a preferred character scope for
readability, not an absolute visible-character ban.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 1.2 Content Constraints & Prohibited Elements (Negative Rules)

To protect the document lifecycle and prevent parser failures, specific formatting,
visual, and hidden elements are restricted across all files. These exclusions are
enforced primarily by stripping hidden or non-printing non-compliant bytes.

Emojis and arbitrary graphical ideograms are strongly discouraged in technical text.
Smart Quotes (curved typographic punctuation marks like " and ") must be automatically
normalized to standard vertical plain-text quote characters by the implementation;
authors should employ standard vertical plain-text quote characters.

No invisible Unicode markers (such as Zero Width Spaces) or hidden ASCII control
characters are permitted, with the sole exception of standard line-termination and
spacing sequences (\n, \r, and \t).



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 1.3 Orthographic Normalization for Prose Safety (Anti-Parsing Collision)

To prevent downstream line-wrapping engines from accidentally generating illegal
unordered list structures during geometric reconstruction, conforming implementations
must programmatically insulate punctuation characters embedded in fluid prose blocks.

Whenever standard hyphen (`-`), plus sign (`+`), or asterisk (`*`) characters are
detected as standalone punctuation markers within a unified Paragraph Block—specifically
when they are bounded by leading and trailing space characters—they must be automatically
normalized into non-syntactic Unicode equivalents.

The transformation matrix must strictly follow these mappings:

- '-'  (Space-Hyphen-Space)        -> Translated to  '—'   (Space-EmDash-Space)
- '+'  (Space-Plus-Space)          -> Translated to  '＋'  (Space-FullWidthPlus-Space)
- '*'  (Space-Asterisk-Space)      -> Translated to  '∗'   (Space-AsteriskOperator-Space)

This rule applies exclusively to parsed prose streams. Active structural list tokens
located at the initialization index of a line or elements inside protected Code Blocks,
Tables, and Blockquotes are strictly exempt from this normalization.




&nbsp;
________________________________________________________________________________

## 2. CANONICAL ELEMENT GLOSSARY

To maintain vocabulary stability throughout this specification, the following element
definitions will be used:

### 2.1 Physical Elements

These are the elements actually edited by authors and visible in the document.

- **Empty Line**: A completely blank line with no characters.
- **Paragraph**: A standard prose text block.
- **List Item**: The entire content of a list item, starting from its bullet point.
  For the purposes of this specification, it holds the semantic value of a Paragraph
  within a list.
- **Headers**: An element of type H1/2/3/4/5/6, defined in Markdown by the **#**
  prefix corresponding to the level it represents. Every Header marks the beginning
  of a Section (see in 2.2).
- **Horizontal Separator (H. Sep.)**: A horizontal dividing line used with semantic/cognitive
  separation function inside content flow.
- **Vertical Separator (V. Sep.)**: A line containing exclusively `&nbsp;`, used
  for controlled vertical breathing in rendered output.
- **Decorators**: Non-semantic, aesthetic separators, currently used for Header decoration
  (typically Horizontal Separators associated with Headers to delimit Sections).
- **Structure Element (Struct. El.)**: See in 2.1.1


#### 2.1.1 Structure Element (Struct. El.)

In this specification, this term refers to any renderable element with semantic significance
that is not explicitly included in the list of Physical Elements, such as:

- **Lists**
- **Tables**
- **Code blocks**
- **Blockquotes**
- **Raw HTML Blocks**
- **Images**
- **Charts/Graphs**


Although Headers, Paragraphs and List Item are, in practice, Structural Elements,
we reserve this term exclusively for the items expressly listed above.



### 2.2 Logical Elements

These are elements whose definitions (provided below) must be cognitively understood
in order for them to be identified and observed.

- **Contiguous Paragraphs**: Any two sequential Paragraphs with no elements between
  them other than Empty Lines.
- **Paragraph Block**: a group of *N* Contiguous Paragraph forming a sequence with
  no elements between them other than Empty Lines, provided they are within the same
  document Section.
- **Section**: The set of all elements contained within the scope of a single Header,
  from that header up to the next header at the same or higher level.
- **Subsection**: Any Section hierarchically subordinate to the Header level of the
  current Section (e.g., H3 belonging to the same H2 create Subsections of the parent
  Section).
- **Section Block**: See in 2.2.1


#### 2.2.1 Section block

Any Section (starting at its respective Header) may contain one or more Section Blocks.
These blocks consist of the set of all Physical Elements directly subordinate to
the same Header, starting after the Header and terminating upon encountering one
of the following elements:

- **Horizontal Separator (H. Sep.)**
- **Subsection**
- **The end of the respective Section**

Among these boundary elements, Subsections and the end of the Section are strictly
exclusive (excluded from the current block). A Horizontal Separator is inclusive
(included within the current Section Block) solely when it functions as a standalone
Semantic Element rather than a header decorator.



### 2.3 Semantic relevance

The definitions below, regarding the semantic relevance of the elements, aim to unequivocally
distinguish items with genuine informational value from those serving merely as decorative
elements or reading aids; they refer exclusively to the items in the Physical Elements
list (see in 2.1).


#### 2.3.1 Non-Relevant Element

The Physical Elements below are always considered semantically **Non-Relevant**.

- **Empty Line**
- **Vertical Separator (V. Sep.)**
- **Decorators** (see in 2.3.3)


#### 2.3.2 Relevant Element

The Physical Elements below are always considered semantically **Relevant**.

- **Paragraph**
- **List Item**
- **Headers**
- **Horizontal Separator (H. Sep.)** (see in 2.3.3)
- **Structure Element (Struct. El.)**


#### 2.3.3 The relevance of Horizontal Separator (H. Sep.)

We define here that a Horizontal Separator is considered Decorative only when it
is placed immediately above a Header and there are only Empty Lines and/or Vertical
Separator (V. Sep.) between them. Any other use of this element is considered semantically
Relevant.




&nbsp;
________________________________________________________________________________

## 3. BASIC LAYOUT & VERTICAL SPACING

This section establishes the fundamental rules of spatial distribution, governing
how structural blocks breathe, are set back, and break lines to maximize readability.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 3.1 Hard Wrapping Constraints

The line wrapping mechanism is a deterministic column rule that accounts for indentation:

- The line length is measured from character index 0, including leading whitespace.
- Text flows naturally up to 80 characters. Wrapping is triggered at the first whitespace
  encountered after crossing this 80-character comfort threshold.
- No standard word or string segment may extend past a strict limit of 120 characters;
  if a word crosses index 120, it must be pushed entirely to the next line.
- Unbroken atomic tokens (such as raw URLs, long file paths, or cryptographic hashes)
  are exempt from the 120-character rule and must occupy their own dedicated line
  without being wrapped or split.
- Wrapped lines inherit the exact indentation depth of the parent block.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 3.2 Contextual Indentation Standard

Whenever sub-items, descriptions, or secondary sentence lines are subordinated to
a parent list row or item, they must align using a strict 2-space soft indentation
format. The `\t` character must not be used for indentation.

```text
- Example Item Title
  This line represents a contextual description indented exactly by 2 spaces.
  This line belongs to the same parent block and maintains the 2-space alignment.
    - Initiating a secondary sub-list requires an additional +2 space shift.
```



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 3.3 Indented Pre-formatted Text Blocks

This indentation model also permits isolated 4-space pre-formatted blocks when a
literal text block is needed. This specific depth must be reserved solely to trigger
the native Markdown pre-formatted code syntax block (`<pre><code>` equivalent in
HTML rendering engines).

```text
    This text segment starts with exactly 4 leading spaces.
    This creates an isolated, pre-formatted plain-text block.
```



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 3.4 Vertical Separator Blocks (V. Sep. / &nbsp;)

The non-breaking space HTML entity (`&nbsp;`) defines the Vertical Separator (V.
Sep.), a line-level layout control used to create controlled vertical spacing in
the rendered output.


#### 3.4.1 Usage

- To be considered a true Vertical Separator, the `&nbsp;` entity must be the sole
  content of a line, without any indentation or extra characters—not even trailing
  spaces.
- Multiple `&nbsp;` entities may be stacked vertically to increase visual depth,
  but they must be located on contiguous, consecutive lines.
- Empty lines between Vertical Separators are considered bad practice, and such spaces
  should be removed.
- Using the `&nbsp;` element in any other way does not constitute a Vertical Separator.


#### 3.4.2 Isolation

The V. Sep. functions exclusively as structural spacing and must never influence,
combine with, or alter the mathematical calculation of standard spacing rules regarding
empty lines between adjacent elements.


#### 3.4.3 Magnetic Alignment and Symmetry Protocol

When a sequential stack of `&nbsp;` entities is positioned as the immediate vertical
neighbor of a Horizontal Separator, they must be magnetically attracted to align
tightly with the dividing line on both sides. This integrated structure — comprising
the Horizontal Separator and its adjacent, tightly bound `&nbsp;` lines — constitutes
a **Composite Block**.

The resulting Composite Block inherits a strict vertical symmetry rule: the total
number of true Empty Lines (pure `\n`) preceding its top boundary must be perfectly
mirrored by an identical number of true Empty Lines following its absolute bottom
boundary.

- **Precedence Exception (Decorator Mode)**: If a Composite Block is intercepted
  as a Header Decorator (see Section 2.3.3), this symmetry rule is completely suspended.
  In such cases, the explicit structural guidelines and fixed voids defined in the
  *Algorithmic Construction Pipeline* (Section 5.2) take absolute precedence.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 3.5 Spacing Between Relevant Elements

Proper spacing between Relevant Elements is the primary technique used in plain-text
documents to achieve a pleasing aesthetic and facilitate a more dynamic reading experience
with reduced visual fatigue.

To strike a coherent balance in applying this spacing, we have defined the following
rules:

- **Spacing Ownership**: The spacing for each Relevant Element refers to the space
  immediately below it and is calculated based on its density (see 3.5.1).
- **Non-Relevant Elements**: The spacing rules defined here do not affect this type
  of element in any way.


#### 3.5.1 Density and Spacing

The density of a Relevant Element is determined by the total number of raw lines
that comprise it (including blank lines). These rules apply to all Relevant Elements,
including lists; however, for list items, there is a section of rules specifically
designed for them.

**Examples**:

1. if a table requires 10 lines of content in total to be represented in the document,
   its density is 10.
2. If a Paragraph spans 3 lines in total, its density is 3.

The denser the block, the greater the visual void required directly beneath it to
maintain a content dispersion suitable for reading.

When a Relevant Element is followed by a Header as the next Relevant Element (ignoring
any blank lines or vertical separators), the spacing used must be the greater of
the two values: the element's own density-based spacing or the spacing corresponding
to the Header level.

The table below shows the number of empty lines to be created below a Relevant Element
based on its 'visual weight in lines':

| Weight / Header     | Density (in lines) | Spacing |
| ------------------- | :----------------: | :-----: |
| Light               |       1 - 6        |    1    |
| Medium / H4; H5; H6 |       7 - 14       |    2    |
| Heavy / H3          |      15 - 21       |    3    |
| Massive / H2        |        22+         |    4    |
| - / H1              |                    |    5    |


##### 3.5.1.1 Spacing adjustments

In general, the table above applies to all Relevant Elements (except List Items).
However, certain adjustments are necessary depending on the nature of the element
in question to avoid distortions that run counter to the spirit of this proposal.
Thus, the following are some specialized rules regarding spacing:

###### 3.5.1.1.1 contiguous paragraphs

The maximum space between two Contiguous Paragraphs is 2 lines, regardless of the
density of the Paragraphs involved.


###### 3.5.1.1.2 block of paragraphs

The maximum space separating a Paragraph Block from a different subsequent Relevant
Element type is 3 lines.


###### 3.5.1.1.3 contiguous structural elements

When a Structural Element is followed by another Structural Element, the minimum
space to be applied between them is 2 lines.


###### 3.5.1.1.4 contiguous headers

If a lower-level Heading (e.g., H3 or H4) immediately follows its direct structural
superior (e.g., H2 or H3) without any Relevant Elements between them, all optional
Non-Relevant Elements — including Decorators — must be completely suppressed, and
the vertical spacing must be reduced to exactly one Empty Line between the two headings.


###### 3.5.1.1.5 exception rule for colons

Any paragraph ending strictly with a colon character (`:`) overrides any density-based
scaling adjustment and must be followed by exactly 1 line.


###### 3.5.1.1.6 symmetry for horizontal separators

Every Horizontal Separator functioning as a standalone Semantic Element (see Sections
2.3.2 and 2.3.3) is bound by a strict structural reflection rule.

The implementation must calculate the exact number of pure Empty Lines (`\n`) located
between the absolute bottom edge of the immediate preceding Relevant Element and
the top edge of the Horizontal Separator itself. The exact same number of intermediate
Empty Lines must then be programmatically injected immediately below the Horizontal
Separator, separating it from the subsequent Relevant Element.


##### 3.5.1.2 Spacing adjustments for List Items and Nested Lists

The spacing between contiguous List Items at the same hierarchical level must follow
the density table below:

| Weight / Header | Density (in lines) | Spacing |
| --------------- | :----------------: | :-----: |
| Light           |       1 - 3        |    0    |
| Medium          |       4 - 6        |    1    |
| Heavy           |         7+         |    2    |

A spacing value of 0 indicates that the subsequent List Item must be placed on the
immediately following line, with no intermediate Empty Lines separating them. This
exception is designed to preserve the structural cohesion of light lists.


##### 3.5.1.2.1 The List Propagation Protocol

To prevent structural fragmentation and maintain unified gestalt proximity within
complex lists, vertical spacing must behave as a shared block-level ecosystem.

If a single List Item within a local list sequence triggers a "Medium" or "Heavy"
weight classification due to its internal content density, a mandatory cascading
propagation rule takes effect:

- The default `Spacing: 0` for all neighboring "Light" items within that specific
  list sequence is immediately overridden.
- The entire local list converts into a homogenous spaced block, where every contiguous
  List Item must be separated by a minimum of exactly 1 Empty Line.

Conforming implementations must track this structural state per local list block
and normalize the vertical voids uniformly upon exit, guaranteeing that a multi-line
mass item does not visually sever the list's perceived continuity.


##### 3.5.1.2.2 Nested Lists

The maximum vertical spacing used to separate the text of a parent item from the
first item of a nested sub-list must be 1 line.

The density table above (3.5.1.2) must also be used to calculate the density and
corresponding spacing for nested lists when returning from the nested context to
the higher-level list—that is, the space between the last item of the sub-list and
the next item in the higher-level list.




&nbsp;
________________________________________________________________________________

## 4. STRUCTURE ELEMENT RULES

This section establishes formatting conventions for advanced technical components,
ensuring structural elements preserve structural clarity when viewed as plain text.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 4.1 Lists & Bullet Points Architecture

This section establishes the structural guidelines for bullet points, enforcing a
strict hierarchical progression of tokens to maximize structural scannability across
nested lists.

1. **Unordered List Token Cascade**: To eliminate visual ambiguity in complex technical
   documentation, conforming implementations must evaluate the nesting depth of any
   unordered list item and programmatically enforce a cyclic, 3-token rotating sequence:


  + **Level 1 (Root Level)**: Must use the standard hyphen character (`-`).
  + **Level 2 (First Nesting Tier)**: Must use the plus sign character (`+`).
  + **Level 3 (Second Nesting Tier)**: Must use the asterisk character (`*`).
  + **Level 4 (Third Nesting Tier)**: Must cycle back to the hyphen character (`-`).
  + **Level 5 (Fourth Nesting Tier)**: Must cycle back to the plus sign character
    (`+`).
  + **Level 6 (Fifth Nesting Tier)**: Must cycle back to the asterisk character (`*`).


2. **Ordered List Standards**: For sequential or step-by-step items, authors must
   employ the classic numerical suffix sequence (`1.`, `2.`, `3.`). The alternative
   parenthesis suffix notation (e.g., `1)`) is completely prohibited and must be
   programmatically normalized to the standard dot notation.


3. **List Token Spacing**: Every list token, regardless of its type or hierarchical
   level, must be followed by exactly 1 trailing space before the text payload begins.
   Multiple spaces or tab sequences are prohibited.

**Example**:

```markdown
- This is a root level item (Level 1)
  + This initiates a secondary sub-list item (Level 2)
    * This represents a third-tier segment (Level 3)
      - This cycles back to a hyphen item (Level 4)
        + This cycles back to a plus sign item (Level 5)
          * This reaches the final allowed deep tier (Level 6)
```



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 4.2 Tables Formatting

Tables embedded inside documentation files must be designed to remain highly readable
and beautifully structured in plain-text mode.

Authors should manually attempt to align data columns cleanly using vertical pipes
(`|`) and dashed header rows (`-`) that approximate equal spacing. Because manual
layout balancing can be highly tedious, conforming implementations will programmatically
recalculate and perfectly justify all table columns upon submission.

When recalculating cell padding, the implementation must respect native Markdown
alignment syntax (e.g., using `:` delimiters). In the absolute absence of an explicit
alignment indicator within the column separator row, left-alignment must be adopted
as the universal default standard.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 4.3 Code Blocks Embedding

All code blocks embedded inside the documentation must be cleanly segregated from
Paragraph blocks to preserve terminal layout integrity.

Every code block must be declared using the triple backtick (\`\`\`) notation. The
language identifier must be appended directly to the opening backtick sequence, without
any intermediate space (e.g., `\`\`\`go`, `\`\`\`json`). Specifying this explicit
language name is highly encouraged to ensure syntax highlighting mappings remain
operational across modern rendering environments.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 4.4 Blockquotes & Quoted Prose Blocks

Blockquote must be treated conservatively and without destructive intervention. Conforming
implementations must preserve the quoted payload and the quote markers without rewriting
the internal textual content.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 4.5 Raw HTML Blocks

Raw HTML blocks must be treated conservatively and without destructive intervention.
Conforming implementations must preserve the original HTML lines verbatim and must
not normalize, rewrite, or restructure the internal content.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 4.6 Horizontal Separators (H. Sep.)

This Section dictates the normalization behavior for Horizontal Separators, dividing
their operational state into either purely aesthetic overlays or standalone semantic
components.

1. **Decorator Interception**: When a Horizontal Separator is identified as a Decorator—meaning
   it is structurally associated with an upcoming Header (see Section 2.3.3) — its
   standard geometry is completely overridden and absorbed by the specific parametric
   rule of the corresponding Header level (see Section 5).


2. **Standalone Semantic State**: When a Horizontal Separator carries standalone
   semantic value (serving as a cognitive break between fluid content blocks), its
   graphical representation must be programmatically normalized into a rhythmic dotted
   line based on the following execution parameters:


  + **Literal Pattern**: `  -----   ` 2 leading spaces, 5 hyphens, 3 trailing spaces
  + **Pattern Length**: 10 characters
  + **Repetitions**: Exactly 7 times
  + **Total Line Length**: 70 characters

Conforming implementations must render standalone semantic Horizontal Separators
by replicating the literal pattern string exactly **N** times, ensuring it is isolated
by a strict vertical breathing space above and below.

**Example**:

```text
any text above

  -----     -----     -----     -----     -----     -----     -----   

any text below
```




&nbsp;
________________________________________________________________________________

## 5. HEADERS & STRUCTURAL VISUAL ANCHORS

This section establishes the universal typography and layout pipeline for Header
elements, condensing execution rules into a single parametric framework based on
hierarchy levels.

The vertical layout engine governs space allocation directly above and below any
Header according to three structural phases:

1. **Upstream Spacing**: As established in Section 3.5.1, any Relevant Element preceding
   a Header is assigned a minimum Empty Line count based on the level of the subsequent
   Header. This space expands if the preceding element is highly dense, but must
   never fall below the designated baseline.


2. **Context Vacuuming**: The implementation must sweep and remove all trailing spaces,
   redundant Empty Lines, or stray Vertical Separators within this boundary zone.
   Only the exact lines required by the upstream element's density are permitted.


3. **Decorator Activation**: The presence of an arbitrary Horizontal Separator within
   this cleared boundary automatically triggers "Decorator Mode," shifting the separator
   from a standalone Semantic Element into a structural anchor bonded to the Header.



### 5.1 The Parametric Header Matrix

The geometric representation, string padding, target lengths, and text casing rules
for all supported Header levels are programmatically derived from the configuration
matrix below:

| Level  | Prefix    | Setext | Case |  Decorator   | Length | Reps | Total Chars |
| ------ | --------- | :----: | :--: | :----------: | :----: | :--: | :---------: |
| **H1** | *None*    |  `=`   |      | `**********` |   10   |  8   |     80      |
| **H2** | `## `     |        | UPP  | `__________` |   10   |  8   |     80      |
| **H3** | `### `    |        |      | `---- ---- ` |   10   |  7   |     70      |
| **H4** | `#### `   |        |      | `---   - - ` |   10   |  6   |     60      |
| **H5** | `##### `  |        |      | `---  -   -` |   10   |  4   |     40      |
| **H6** | `###### ` |        | LOW  |   `   ---`   |   6    |  5   |     30      |



### 5.2 Algorithmic Construction Pipeline

When Conforming Implementations render or normalize a Header element in Decorator
Mode, they must follow a strict vertical generation sequence:

1. **The Breathing Header**: Inject exactly 1 standalone `&nbsp;` (Vertical Separator)
   line to act as the top visual boundary buffer.


2. **The Graphic Overline**: Generate the Horizontal Separator on the immediate next
   line by replicating the literal string block defined in the **Decorator** column
   exactly the number of times specified in the **Reps** column.


  + *Technical Note (H1 Compatibility)*: The continuous asterisk sequence (`*`) generated
    for H1 is strictly tailored for high-fidelity plain-text environments and modern
    CommonMark-compliant engines. Rendering or parsing anomalies may exclusively
    manifest within outdated, legacy HTML previewers that lack contemporary token
    processing architectures.


3. **The Interstitial Void**: Insert exactly 1 Empty Line (`\n`) to decouple the
   graphic layout line from the upcoming text block.


4. **The Payload**: Output the text content. Prepend the corresponding marker from
   the **Prefix** column (if any). The text payload must be normalized according
   to the **Case** column instructions:
  + If **Case** is `UPP`, convert the entire text payload to strict uppercase.
  + If **Case** is `LOW`, convert the entire text payload to strict lowercase.
  + If **Case** is empty, preserve the author's original casing.


5. **The Setext Anchor (H1 Exclusive)**: For Level 1 Headers only, append a trailing
   underline row using the character from the **Setext** column, scaled dynamically
   based on the payload length:


  + Up to 32 characters: Underline length = 32.
  + 33 to 64 characters: Underline length = 64.
  + 65+ characters: Underline length = 80.


6. **The Downstream Release**: After outputting the text payload (and any associated
   Setext underline), the implementation must immediately inject exactly 1 pure Empty
   Line (`\n`) below the Header block before the initiation of any subsequent Relevant
   Element, establishing a universal vertical margin for content onset.



### 5.3 Live Visual Compilation Block

This block provides an exhaustive, real-world visual demonstration of how every single
Header level must physically materialize in raw text format when Decorator Mode is
active, matching the exact character math of the configuration matrix:

```text
&nbsp;
********************************************************************************

Document Main Title (H1)
================================


&nbsp;
________________________________________________________________________________

## MAJOR DOMAIN BOUNDARY TEXT IN UPPERCASE (H2)


&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### Atomic Category Sub-Section (H3)


&nbsp;
---   - - ---   - - ---   - - ---   - - ---   - - ---   - - 

#### Explicit Rule or Technical Criteria (H4)


&nbsp;
---  -   ----  -   ----  -   ----  -   -

##### Micro-Structural Label Parameter (H5)


&nbsp;
   ---   ---   ---   ---   ---

###### deepest allowed conceptual nesting layer (h6)
```