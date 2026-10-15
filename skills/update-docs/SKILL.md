---
name: update-docs
description: Write new docs or fix existing ones, such as READMEs and guides. Use after every change or when asked to write docs.
---

# Update docs

Apply this skill to the requested changes, the files the operator names, or the doc the operator asks for. Code comments are out of scope. The reader of a doc is a person who does not know the project or its history.

## Session artifacts
A session artifact is a detail that is in a doc only because an AI coding session, this one or an earlier one, dealt with it. The reader does not need it. Typical examples are a note about a fixed bug, an answer to one operator's question, and an approach that the project does not use. Other signs: a detail much more specific than the text around it, or a warning against a mistake that the reader cannot make. Do not write session artifacts.

A note about history is also a session artifact. Describe the current state. Do not write "new", "now", "no longer", or "was changed to". The commit message holds the history.

## After a change
Find each doc that the change made false. Fix it in the same pass, because a stale doc is worse than no doc. Change only the false sentences. Delete each session artifact in the doc. Do not reorder or rewrite the other parts of the doc unless the operator asks. If no doc covers a change that the reader must know about, add the smallest section for it. Apply the Content and Language rules to each sentence that you write.

## A new doc
The reader wants to understand what the project does, and reads from the top like a story. First, tell what the project is and which problem it solves. Then explain how it works, at the level that lets the reader predict what it does. Show one typical use as an example.

Order the sections by the questions of the reader, not by the structure of the project. Give each section one job. Answer each question at the point where the reader asks it.

## Content
Give an example, a real case, or a number that the reader can check, not a description. State limits and costs clearly. Define a term in a clause when you first use it, or do not use the term.

Describe each effect that the reader must know about. Tell what the project changes, what it keeps and for how long, and what it sends and receives. Do not describe what only the code uses, such as module layout and call order. A refactor makes these false.

State each fact in one place. Link to it from the other places. Two copies of a fact drift apart.

For this reason, do not copy the usage reference into the doc. Flags, options, and defaults belong in the tool itself, such as its `--help` output. Tell the reader where the full usage is. If the usage help is missing or false, tell the operator.

Use a mermaid diagram only when a flow or a structure is spatial. Use few nodes, labeled edges, and no styling.

## Language
Write in ASD-STE-100 Simplified Technical English. Use one word for one meaning, and one meaning for one word. For example, do not call the same thing "sandbox" in one sentence and "container" in the next. Write a maximum of 20 words in an instruction and 25 words in a description. Write one instruction in each sentence. Use the active voice.

Do not use these LLM habits: jargon, lists of fragments, tables that repeat the text, and closing summaries. Delete each sentence that could be in marketing text.

## Last check
Read the doc again as the reader. Each place where the reader would stop to ask a question is a gap. Fill it. Delete each paragraph that the reader would skip.
