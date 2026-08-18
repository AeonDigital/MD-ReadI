Writing Tips
================================

> Companion guide for human and AI authors writing technical documentation.

&nbsp;

This document consolidates writing-oriented guidance extracted from the main specification.
Its purpose is to preserve authoring best practices in a separate scope while the
main specification remains focused on deterministic technical rules.




&nbsp;
________________________________________________________________________________

## 1. COGNITIVE WRITING STRATEGIES

To optimize rapid information scanning and minimize human cognitive fatigue, authors
should enforce semantic parallelism and structural predictability.

Authors are encouraged to deliberately utilize identical phrase structures, repetitive
core terminology, and mirrored paragraph layouts across similar technical descriptions.
This structural repetition serves as a visual mnemonic device; once the reader comprehends
the syntax of an initial definition, succeeding definitions require near-zero cognitive
processing to interpret, allowing the mind to focus exclusively on variable parameters.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 1.1 Systematic Section Numbering

Every standalone section, sub-section, and granular criterion should be bound to
a strict decimal indexing hierarchy (e.g., 1., 1.1, 1.1.1).

This indexing facilitates precise cross-referencing for both readers and tools, helps
isolate logical boundaries, and reinforces consistency across long technical documents.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 1.2 Storytelling Order for Technical Documentation

To reduce ambiguity and improve readability, content should progress from high-level
foundations to specific rules (root-to-leaf narrative flow).

Recommended sequencing pattern:

1. File-level constraints (encoding, character model, control bytes).
2. Canonical element glossary.
3. Derived taxonomies (e.g., relevant vs non-relevant).
4. Global rules that apply to all elements.
5. Specialized rules for each element type.
6. Quick-reference matrices and implementation overrides.




&nbsp;
________________________________________________________________________________

## 2. DOCUMENT SCOPE & ARCHITECTURE

&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 2.1 Single-Topic Principle

Every Markdown document should contain exactly one H1 header, positioned at the very
beginning of the file, declaring its singular subject.

All content within the document must serve that one declared topic. If a second independent
topic naturally arises during writing, it must be extracted into a dedicated new
file rather than appended to the existing one. This constraint preserves semantic
cohesion and keeps each file self-contained, predictable, and easy to reference.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 2.2 Document Length Guidelines

To sustain a coherent narrative and prevent cognitive overload, authors should treat
document length as an active quality signal:

- **500 lines**: The optimal target length for a complete, well-scoped document.
  Documents approaching this mark should be reviewed to confirm the subject has not
  silently expanded beyond its declared scope.
- **1000 lines**: A hard warning threshold. Reaching this limit is a strong indicator
  that the subject has grown too large for a single file and must be decomposed into
  smaller, focused documents.

These boundaries are not arbitrary size limits—they reflect the cognitive load imposed
on both human readers scanning raw text and AI agents ingesting context.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 2.3 Multi-Document Index Architecture

When a subject requires more than one file to be fully documented, a dedicated index
file must be created at the root of that documentation set.

The index file must contain:

- A list of all files belonging to the documentation set.
- A hyperlink to each file.
- A brief single-sentence description of each file's scope.

Beyond the flat file list, authors are strongly encouraged to expand the index by
listing the internal sub-items (sections and subsections) of each document directly
beneath its entry. This creates a navigable, hierarchical tree of topics that serves
two audiences simultaneously:

- **Human readers**: can scan the full map of the subject at a glance and jump directly
  to the relevant file and section without opening every document.
- **AI agents**: can parse the indexed tree to efficiently locate specific information
  without needing to traverse every file sequentially.

A well-structured index transforms a collection of files into a coherent, addressable
knowledge graph.