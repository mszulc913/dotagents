---
name: update-docs
description: Keep docs true to the code and worth reading; cut the LLM tells. Use after every change.
---

# Update docs

Apply to the requested changes or the files the operator names. Find every doc the change made false and fix it in the same pass; stale docs are worse than none. If the change matters to users and no doc covers it, add the smallest section that does. Doc comments on public code state the contract the signature cannot show; paraphrasing the signature dies. Docs are a story: the reader arrives with a goal, so order sections by that goal, not by the code layout, and give each section one job. A section that answers no reader question dies.

Write with proof, not praise: a runnable example with its real output beats a paragraph of prose, and every claim carries a number, a link, or the actual behavior. Show the tradeoff; never hide a cost. No jargon; define a term in a clause, by contrast with what it is not, or drop it. Mechanics stay exact: file names, load order, precedence, defaults. The reader is a person; address them directly and use the imperative for actions. Kill the LLM tells: emoji headers, "seamlessly", "powerful", "easily", "leverage", bullet soup, tables that restate prose, sections padded to equal length. If a sentence would survive in marketing, it dies here.

Diagrams are mermaid, and only when flow or structure is truly spatial. Clean mermaid: few nodes, labeled edges, no styling, no decoration; if a list tells it better, use the list.