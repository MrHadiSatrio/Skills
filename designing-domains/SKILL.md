---
name: designing-domains
description: A grammar-driven method for designing domain models before implementation — parsing expert narrative into a glossary, organisms, contracts, absences, and commands. Use when specifying or designing a domain model, or when directed by another skill.
---

# Designing Domains

A domain model is discovered by listening, not invented at a keyboard. Domain experts already say everything the model needs — the nouns, the verbs, the rules, even the absences — though rarely all in the first telling — and grammar is the parser that turns their speech into a specification. Design happens before implementation and is expressed entirely in language; code comes later, and belongs to other skills.

**Precedence:** Where the project already has a domain vocabulary or model, extend it — never rename or remodel uninvited. Surface tensions between the existing model and this method to the user; the identical precedence rule for code lives in `writing-organism-oriented-code`, and that copy wins for code.

## 1. The Grammar Pass

Collect the domain narrative — expert interviews, tickets, README prose, the user's own description — and parse it grammatically. Each grammatical form maps to one kind of design element:

| Grammar                                    | Becomes                                        | Test                          |
|--------------------------------------------|------------------------------------------------|-------------------------------|
| Noun                                       | Organism, value, or glossary-only              | The noun test (section 4)     |
| Plural noun                                | A collection contract (`Moments`, `Places`)    | Plurals are contracts, not lists |
| Qualified plural ("notable moments nearby")| Filtering wrappers over the collection contract| One qualifier, one wrapper    |
| Verb from an outside actor                 | Command, as an imperative phrase               | The verb test (section 7)     |
| Verb within the narrative                  | Behavior owned by an organism                  | The verb test (section 7)     |
| Adjective or state ("committed", "notable")| Boolean predicate, named as an English assertion | Reads aloud as true or false |
| "Must", "only", "until" clause             | Invariant, stated as a complete sentence       | Section 5                     |
| "No X", "unknown", "nowhere"               | Named absence                                  | The absence test (section 6)  |
| "Exactly one of" clause                    | A boundary question                            | Section 8                     |

A worked parse. The narrative:

> A traveler captures a moment wherever they are. When we cannot name where
> they are, the moment still happens — its place is simply nowhere we know.
> A moment may be edited until it is committed; after that it can only be
> forgotten.

| Fragment                          | Grammar              | Design element                                          |
|-----------------------------------|----------------------|---------------------------------------------------------|
| traveler, moment, place           | Nouns                | `Moment` and `Place` are organisms; traveler stays glossary-only (no owned behavior yet) |
| captures a moment                 | Verb, outside actor  | Command: Capture A Moment                                |
| nowhere we know                   | Absence              | `NullIsland` — a `Place` whose distances are unknown     |
| may be edited until committed     | "Until" clause       | Invariant: "A moment accepts updates only until it is committed." Plus a read/write contract split |
| can only be forgotten             | Verb + vocabulary    | Command: Forget A Moment; glossary records *forget*, not *delete* |

Parse the whole narrative before designing anything — a noun classified early is often reclassified by a later sentence.

## 2. The Clarifying Dialogue

The first narrative is never complete. Domain insight emerges through back-and-forth — the expert tells a story, the parse exposes its gaps, and the questions draw out the next layer of story. Treat the opening prompt as the first interview, not the finished narrative, and keep the dialogue two-way until the shape is solid.

- **Every parse gap is a question**, and each kind of gap has a question form:

| Gap surfaced by the parse              | Question to ask                                                                      |
|----------------------------------------|--------------------------------------------------------------------------------------|
| A noun the noun test cannot classify   | "What does a <noun> do — what questions can it answer, what rules does it enforce?"  |
| A verb with no owner                   | "Who or what makes <verb> happen — and what goes wrong when it is done badly?"       |
| An invariant no organism protects      | "Whose job is it that '<invariant sentence>' stays true?"                            |
| An absence with undefined behavior     | "When there is no <thing>, does the story carry on, or stop?"                        |
| One word carrying two meanings         | "You use <word> for both X and Y — are they the same thing?"                         |
| An "exactly one of" of unclear closure | "Could a new kind of <thing> ever appear, or are these all there will ever be?"      |

- **Ask in rounds, in domain words.** Batch the gaps from a full parse into one set of questions (AskUserQuestion where available; in plain text otherwise), phrased in the glossary's vocabulary — the conversation test (section 3) applies to questions as much as to names.
- **Answers are narrative.** Feed every answer back through the grammar pass; it will classify some elements and expose new gaps. Expect several rounds.
- **The stopping rule.** The dialogue has converged when a full parse round leaves every noun classified, every invariant owned, every absence behaviorally defined, and every vocabulary collision resolved — that is the solid shape. Stop asking only at this bar; keep going past it while the expert is still volunteering corrections.
- **When the expert is unreachable**, record each unanswered question under the spec's open questions and mark every element that depends on one as provisional — never resolve a gap by inventing the answer (see "What NOT to Do").

Continuing section 1's worked parse, which left *traveler* glossary-only and no rule about who may forget a moment:

> "A committed moment 'can only be forgotten' — forgotten by whom? May one
> traveler forget another traveler's moment?"

An answer of "only its own traveler may forget it" is new narrative: *traveler* is now compared (this traveler versus another), so the noun test (section 4) promotes it from glossary-only to a value, and `Moment` gains the invariant "A moment may be forgotten only by its traveler."

## 3. The Glossary

The glossary is the spec's foundation: the ubiquitous language, one entry per concept.

- **Every term passes the conversation test** — "would a domain expert use this word in conversation?" If not, find the word they would use. This restates `writing-prose-like-code`, "Domain Vocabulary over Technical Vocabulary", which remains canonical.
- **One word per concept, one concept per word.** Two terms for one concept: pick one, record the other as a rejected synonym. One term for two concepts: split them — the collision usually marks a hidden boundary (section 8).
- **Record rejected synonyms with the reason** — "*delete*: rejected; people forget moments, databases delete rows." The rejection is design knowledge; without it the next contributor reintroduces the word.
- **Existing vocabulary wins.** In a project that already speaks, adopt its terms even where this method would choose otherwise, and surface the tension rather than renaming.

## 4. Organisms and Values

Apply **the noun test** to every noun that survived the grammar pass:

- **Does the narrative make it answer questions or enforce rules about itself?** It is an organism — it owns behavior and protects invariants. The design-level statement of `writing-organism-oriented-code`, "Object Design", which remains canonical: objects own behavior; no anemic models.
- **Is it measured, compared, or exchanged as a quantity?** It is a value — self-validating, self-describing, comparable. A `Timestamp` knows its range; a `Sentiment` refuses values outside its scale.
- **Neither?** It stays glossary-only until behavior appears. Actors (the traveler, the admin) usually stay glossary-only — they act *on* the system through commands, they are not modeled *in* it. Promote an actor to organism only when the system itself must hold rules about them.

Each organism's spec entry states: its name, a one-sentence description in glossary words, the behaviors it owns, the invariants it protects, and the other organisms it collaborates with. An entry with an empty behaviors list is a defect — reclassify it as a value or demote it to the glossary.

## 5. Invariants

Every "must", "only", "always", "until", or "never" in the narrative is an invariant.

- **State each invariant as a complete English sentence with punctuation** — "A moment accepts updates only until it is committed." This restates `writing-prose-like-code`, "Validation as Complete Sentences", which remains canonical; at design time the sentence *is* the invariant, not just its error message.
- **Assign each invariant to the one organism that protects it.** An invariant no organism can own marks a missing concept — parse again around that sentence.
- **A rule that ends the story is a precondition, not an invariant.** "A moment cannot exist without a timestamp" stops the narrative — it belongs in the owning organism's construction, stated as the same complete sentence.

## 6. Absences

Apply **the absence test** to every "no X", "unknown", "not yet", or "nowhere" in the narrative:

- **Does the narrative keep talking about the thing while it is missing?** Then absence is a domain concept — name it with a domain word and give it defined behavior. "Nowhere we know" becomes `NullIsland`, a real `Place` whose name is "Null Island" and whose distances are unknown. Never a nullable.
- **Does the narrative stop when the thing is missing?** Then it is a precondition (section 5), not an absence — do not invent a null object for an impossible case.
- **Absences answer every question their contract asks**, in the vocabulary of "unknown", "empty", or "nobody" — an absence that throws on use is a nullable wearing a costume.
- **Escape hatch:** at wire and storage boundaries (section 8), optionality may be represented as the format demands; convert to the named absence at the edge, so the domain never sees it.

## 7. Commands and Behaviors

Apply **the verb test** to every verb:

- **Initiated by an actor outside the system?** It is a command, named as an imperative verb phrase — "Capture A Moment", "Show Stories". The article "A" signals a single-entity operation; aggregates drop it. This restates `writing-prose-like-code`, "Commands as Imperative Verb Phrases", which remains canonical.
- **Happening within the narrative?** It is behavior owned by an organism. When two organisms plausibly claim a behavior, the owner is the one whose invariant would be violated by doing it wrong.
- **The command list is the system's table of contents.** A reader of the spec should learn everything the system does by reading the command names aloud.

## 8. Boundaries

Mark where the model meets the world — the spec must say where its own rules stop:

- **"Exactly one of" clauses ask a boundary question.** If the closed set comes from a protocol, wire format, or event stream, it is a decision table at the edge. If it arises inside the domain, each alternative is one implementation of a shared contract — the set stays open.
- **Data without behavior lives only at edges.** Wire formats, database rows, and API payloads may be bags of data; the boundary converts them to organisms and values on the way in, and back on the way out.
- **Persistence, frameworks, and deployment are boundary concerns.** The spec names the boundary ("moments are stored somewhere durable") and stops; choosing the technology is an architecture decision — record it per `working-with-adr-tracking-projects`, "Is this decision ADR-worthy?", written in the glossary's vocabulary.

## 9. Contracts

Express each organism and collection as a minimal contract, in pseudocode only:

- **Interface width is a budget** — every method added makes each future wrapper, fake, absence, filter, and composite more expensive. The design-level statement of `writing-organism-oriented-code`, "Object Design", which remains canonical.
- **Split reading from writing at design time.** If any part of the narrative only observes a concept, the reading contract stands alone and the writing contract extends it.
- **Qualified plurals become wrappers over the collection contract**, one qualifier each — "notable moments near here" is two wrappers over `Moments`, and the composition reads as the phrase itself.

The shape, in pseudocode — realizations belong to `writing-organism-oriented-code` and are deliberately absent here:

```
interface Moment                          # what the narrative observes
    place, timestamp, sentiment

interface EditableMoment extends Moment   # what "may be edited until committed" adds
    update(...), commit()

interface Moments                         # the plural is a contract too
    new() -> EditableMoment
    forget(moment)
```

## 10. The Spec Artifact

The deliverable is a document, ordered so each section builds on the previous: the source narrative (quoted or linked), the glossary, organisms and values, invariants, absences, commands, contracts, boundaries, and open questions — the unanswered remainder of the clarifying dialogue (section 2). Keep it scannable — a bounded area of the domain fits in a few pages, and a spec too long to read aloud has drifted into design documentation.

Decisions made *while* speccing that pick between viable alternatives get ADRs per `working-with-adr-tracking-projects`, "Creating New ADRs" — the spec describes the model; the ADR records why it is this model and not the other one.

## 11. Realization and Planning

- **Hand off to the code skills.** Implementation follows `writing-organism-oriented-code` and `writing-prose-like-code`; direct the implementing agent to load them (Skill tool unavailable → read the sibling skills' SKILL.md directly).
- **Plans carry the spec's substance verbatim.** An implementation plan built from a spec includes the glossary and the contracts themselves, not references to them — do not assume the executing agent has access to this skill or to the spec.
- **The spec is falsifiable, not sacred.** When implementation discovers the narrative was wrong, amend the spec and its glossary first, then the code — never let the two drift.

## 12. What NOT to Do

- Don't parse the first prompt as if it were the whole narrative — presume incompleteness and ask (section 2). Exception: when the expert is unreachable, record open questions and mark dependent elements provisional rather than stalling.
- Don't use technical vocabulary in the spec — no `Entry` where the domain says `Moment`, no `handle` where it says `sink`. Universally-lexicalized short forms (`id`, `url`) are permitted, and an existing project's established vocabulary wins (section 3).
- Don't use pattern jargon where a domain word serves — the plural contract `Moments` is what other methods call a Repository; the spec never says Repository, Factory, or Manager. Exception: when integrating with a codebase that already speaks the jargon, record the mapping in the glossary instead of fighting it.
- Don't keep anemic concepts — a noun with no behavior is a value or a glossary entry, never an organism (section 4).
- Don't write nullable absences into contracts — design the named absence; optionality survives only at wire and storage boundaries, converted at the edge (section 6).
- Don't put implementation code in the spec — contracts are pseudocode. Exception: one realization example, marked non-normative, when stakeholders need to see the target language.
- Don't specify persistence, frameworks, or deployment inside the domain spec — name the boundary and record the choice as an ADR (section 8).
- Don't start from the database schema or the API shape — parse the narrative first; edges are derived from the model, never the reverse.
- Don't invent vocabulary the narrative doesn't contain — a concept you need but experts never name is a question for the experts, recorded under open questions, not a term you coin unilaterally. Exception: named absences (`NullIsland`, `Nobody`) are legitimately coined, since experts rarely name their nothings.
