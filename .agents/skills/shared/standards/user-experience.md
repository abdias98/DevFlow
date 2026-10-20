# DevFlow Engineering Standards: User Experience (Technology-Agnostic)

> **Version:** 1.0.0 | **Last Updated:** 2026-10-20

> **Apply only if:** the change affects what a person sees, decides or types in any interface — a view, route or navigation in a GUI (web, mobile, desktop); a multi-step task; a destructive or long-running action; user-visible text; or a command, flag or output of a command-line interface. Machine-to-machine APIs belong to `rest-api.md`.

This standard covers the experience of a **flow**: how a person finds their way, what happens when they make a mistake, whether their work survives, how a wait feels, how the system talks to them, in which language, and — on a terminal — how the command behaves for people and for scripts. The look and states of a single element belong to `ui-design.md`; making the interface perceivable and operable for everyone belongs to `accessibility.md`. When a rule here touches either, it cites them instead of restating them.

**Basis.** Each section names its sources and the strength of the evidence behind it, because not every rule rests on the same ground:

- **Strong** — an international standard or replicated research: the interaction principles of **ISO 9241-110:2020** (suitability for the user's tasks, self-descriptiveness, conformity with user expectations, learnability, controllability, use error robustness, user engagement); the usability definition and *context of use* of **ISO 9241-11:2018**; the response-time limits of Miller (1968), Card, Robertson & Mackinlay (1991) and Nielsen (1993); **WCAG 2.2**; the **Unicode CLDR** plural rules.
- **Guideline consensus** — recognized public guidance that agrees but has no controlled study comparing the alternatives: Nielsen's usability heuristics, NN/g's error-message guidelines, the GOV.UK Design System, the GNOME Human Interface Guidelines, Shneiderman's golden rules, the W3C internationalization guidance, and the Command Line Interface Guidelines (clig.dev).
- **Moderate** — a sound expectation with weaker formal backing; such rules are never BLOCK (§14).

ISO texts are not reproduced: this standard cites the principles by name. Full references are in §18.

**Out of scope on purpose:** ISO 9241-110's *user engagement* principle (motivating continued use). It cannot be verified in a code review and is where dark patterns live; this standard is limited to effectiveness, efficiency and the user's control.

## 1. Task Suitability & Orientation

- **What:** A person uses an interface to get a task done. Every screen, step or command either helps that task or stands in its way — and at every moment the person should be able to tell where they are, what they can do, and what just happened.
- **Basis:** ISO 9241-110 *suitability for the user's tasks* and *self-descriptiveness*; Nielsen heuristics #1 (visibility of system status) and #2 (match between system and the real world). Evidence: strong.
- **DO:**
  - Design the flow around the user's task as stated in the spec's context of use (§16), not around how the data or the code is organized.
  - Show progress through a multi-step task — the current step and how many remain — and let the person see what they already entered before the final commit.
  - Make the result of every action visible: what changed, where it is now, and what the person can do next.
- **DON'T:**
  - Add steps, screens or prompts that serve the implementation (a confirmation of something already visible, a choice the system could infer) rather than the task.
  - Leave a person on a screen with no visible way forward or back.

## 2. Navigation & State

- **What:** People expect the navigation controls of their platform to behave consistently: "back" returns to where they were, reloading keeps what they were looking at, and a link they share opens the same view.
- **Basis:** ISO 9241-110 *conformity with user expectations*; Nielsen #4 (consistency and standards); W3C *Architecture of the World Wide Web* ("assign distinct URIs to distinct resources"). Evidence: **moderate** — the W3C principle concerns resources rather than interface states, so the rules below are expectations, never BLOCK.
- **DO:**
  - Give every view a person would plausibly bookmark, share or return to (a record, a search with its filters, a tab of a detail page) its own URL or deep link.
  - Keep filters, sorting, pagination and scroll position when the person reloads or comes back to a list.
  - Make the platform's "back" return to the previous view.
- **DON'T:**
  - Use "back" to undo an action, or make it leave the application from inside a multi-view flow because the views never entered the history.
  - Put in the URL what must not be shared or replayed (credentials, one-time tokens, the identity of another user's data the recipient may not see).

## 3. Error Prevention & Destructive Actions

- **What:** People make mistakes — slips of the hand and misunderstandings alike. The interface first makes them harder to make, then makes them cheap to undo.
- **Basis:** ISO 9241-110 *use error robustness*; Nielsen #3 (user control and freedom) and #5 (error prevention); GNOME HIG *Dialogs*; Shneiderman's "permit easy reversal of actions". Evidence: strong for prevention and reversal as principles; **guideline consensus** for undo over confirmation — people habitually accept confirmation dialogs without reading them, but no controlled study compares the two directly.
- **DO:**
  - Prevent before you report: disable or omit actions that cannot succeed in the current state, choose safe defaults, and accept input whose intent is clear (a date in an unusual but unambiguous format) instead of rejecting it.
  - For a reversible destructive action, act immediately and offer **undo** (for example a notification with an undo action), rather than asking first.
  - When undo is not possible, ask for confirmation that names the object and the consequence, with an affirmative button labelled by the specific action ("Delete 3 invoices", "Discard changes") — never a generic "OK" or "Yes".
  - For an irreversible action with a large blast radius (a production database, an account, a repository), require a confirmation that cannot be given by reflex, such as typing the resource's name.
- **DON'T:**
  - Ask for confirmation of routine, reversible actions — it trains people to accept every dialog, including the one that matters.
  - Perform an irreversible, destructive action with neither confirmation nor undo.

## 4. Error Messages & Recovery

- **What:** When something does go wrong, the message is the only help the person gets. It has to say what happened and how to get out of it, where the problem is, in their language.
- **Basis:** ISO 9241-110 *use error robustness*; Nielsen #9 (help users recognize, diagnose and recover from errors); NN/g *Error-Message Guidelines*; GOV.UK Design System *Error message*; clig.dev *Errors*. Evidence: guideline consensus.
- **DO:**
  - Show the message next to what caused it, and make its prominence match its severity — a modal dialog only for a serious error that stops the task.
  - Say what went wrong in plain words and what the person can do about it: an instruction for something missing ("Enter your email address"), a description for something wrong ("The date must be in the future").
  - Keep everything the person entered, including the parts that were correct, so they fix only what is wrong.
  - Offer to try again when retrying is safe for this operation (`concurrency.md §5` owns when it is).
  - Give unexpected failures a reference the person can quote to support, without exposing internals (`error-handling.md §5`).
- **DON'T:**
  - Show an error before the person has had a chance to act (validating a field while they are still typing it — the field-level timing rule is `ui-design.md §9`).
  - Use a generic message ("An error occurred", "Something went wrong", "Invalid input") when the cause is known.
  - Blame the person, apologize instead of helping, or joke — none of it helps them recover.

## 5. Protecting User Work

- **What:** Losing work someone already put in — a long form, an edited document, a configuration — is the most expensive failure an interface can inflict, because the person must redo it and stops trusting the system.
- **Basis:** ISO 9241-110 *controllability* and *use error robustness*; WCAG 2.2 success criteria 2.2.5 *Re-authenticating* and 2.2.6 *Timeouts* (Level AAA). Evidence: strong.
- **DO:**
  - Warn before the person leaves a view with unsaved changes, and say what will be lost.
  - In long tasks, save a draft (automatically or on request) so the person can stop and continue later.
  - When a session expires or the person must re-authenticate, keep what they entered and let them continue after signing in again.
  - Make the save state visible — saved, saving, unsaved changes, save failed.
  - When someone else changed the same data, explain the conflict and the person's options instead of silently overwriting either version.
- **DON'T:**
  - Discard input because of a timeout, a navigation, a failed submission or a re-login.
  - Claim work is saved before the save has actually succeeded.

## 6. Feedback & Response Time

- **What:** How long an action takes changes what the person needs to see. The limits come from how people perceive time, not from how fast the system can go.
- **Basis:** Nielsen #1; Miller (1968), Card, Robertson & Mackinlay (1991), Nielsen (1993) — the three response-time limits; clig.dev *Robustness*. Evidence: strong. The limits are perceptual thresholds, not service-level targets.
- **DO:**
  - Respond to every action, in proportion to the action: a small change gets a small acknowledgement, a commit gets a clear confirmation.
  - Within about **0.1 s** the response feels instantaneous and needs no indicator; beyond about **1 s**, show that the system is working; beyond about **10 s**, show a percent-done or step-based progress indicator, an estimate of when it will finish, and a visible way to cancel — and let the person keep working, telling them when it completes.
  - If a result is shown optimistically before the operation is confirmed, make the rollback visible when it fails (the mechanism for discarding superseded results is `state-lifecycle.md §6`).
- **DON'T:**
  - Leave a person unable to tell "still working" from "stuck".
  - Show an indeterminate spinner for a long operation whose progress the system actually knows.

## 7. Learnability, Help & Efficiency

- **What:** A first-time user needs to discover what the interface can do; a frequent user needs to do it fast. Neither should have to remember what the interface could have shown them.
- **Basis:** ISO 9241-110 *learnability* and *controllability* (which includes individualization since the 2020 edition); Nielsen #6 (recognition rather than recall), #7 (flexibility and efficiency of use) and #10 (help and documentation). Evidence: strong.
- **DO:**
  - Show the options and information a step needs instead of making the person remember them from a previous step.
  - Put help where the question arises (a hint next to a field, an example), focused on the task.
  - Offer accelerators to frequent users (shortcuts, bulk actions, remembered choices) without putting them in a novice's way.
  - Remember a person's own settings (language, format, layout) between visits.
- **DON'T:**
  - Require a code, identifier or value the interface already knows or showed a screen ago.

## 8. UX Writing

- **What:** The words of an interface are part of its design: a term used two ways or a button that does not say what it does causes errors as surely as a broken layout.
- **Basis:** Nielsen #2 and #4; GOV.UK Design System; GNOME HIG (button labels). Evidence: guideline consensus.
- **DO:**
  - Use one name per concept across the whole interface, the same name the person uses for it.
  - Label buttons and actions with the specific verb of what they do ("Save draft", "Send invoice").
  - Keep the rule on jargon and plain language in `ui-design.md §8`; apply it to every message this standard covers.
- **DON'T:**
  - Call the same thing by two names in different places, or one name for two things.

## 9. Internationalization

- **What:** Text that reads well in one language breaks in another: translations are longer, plurals have more forms, and dates and numbers are written differently.
- **Basis:** W3C Internationalization *Text size in translation* (data from IBM's global design guidelines); Unicode CLDR *Plural rules*. Evidence: strong.
- **DO** — always, even in a single-language product:
  - Build messages as whole sentences with placeholders, never by concatenating fragments.
  - Format dates, times, numbers and currency with the stack's locale-aware formatting, not by hand.
- **DO** — when the product ships in more than one locale:
  - Keep every user-visible string out of the code, in the stack's message catalog.
  - Express plurals with the CLDR categories through the stack's message format: always provide `other`, and never assume `one` means only the number 1.
  - Leave room for translation growth according to string length — strings of up to 10 characters can grow to 200–300 %, 11–20 to 180–200 %, 21–30 to 160–180 %, 31–50 to 140–160 %, over 70 characters to about 130 % — with layouts that wrap instead of fixed-width containers.
  - Support right-to-left layout when the product supports a right-to-left language.
- **DON'T:**
  - Build a sentence from fragments ("You have " + n + " items") — word order, grammar and plural forms differ by language.
  - Abbreviate to save space without checking the target languages can be abbreviated the same way.

## 10. Command-Line Interfaces

- **What:** A command-line tool has two users at once: a person at a terminal and a script that runs it. It has to be clear to the first and predictable to the second.
- **Basis:** Command Line Interface Guidelines (clig.dev) — *Help*, *Output*, *Errors*, *Arguments and flags*, *Interactivity*, *Robustness*; the `NO_COLOR` convention (as stated by clig.dev); POSIX exit status. Evidence: guideline consensus, except exit status (an operating-system contract).
- **DO:**
  - Provide `-h` and `--help` on every command and subcommand; when required arguments are missing, show a short usage with an example and point to `--help`.
  - Send the command's result to stdout and messages, progress, warnings and errors to stderr.
  - Offer `--json` for machine-readable output, and `--plain` when the human-formatted output would break line-based tools.
  - Use color and animation only when the output is a terminal; disable them when `NO_COLOR` is set and not empty, when `TERM` is `dumb`, or with `--no-color`.
  - Prompt only when stdin is a terminal, and never require a prompt: every answer has a flag, and `--no-input` disables prompts entirely (failing with the flag the person must pass).
  - Follow the conventional names: `-n`/`--dry-run` to preview a change, `-f`/`--force` to skip a confirmation, `-q`/`--quiet` to reduce output; scale confirmation to severity, and for a severe action accept a scriptable `--confirm=<resource-name>`.
  - Exit with 0 on success and non-zero on failure, with distinct codes for the failures a script would handle differently.
  - Print something within about 100 ms, and show progress on long operations.
- **DON'T:**
  - Accept secrets (passwords, tokens) as flag values — they end up in shell history and process listings; read them from a file, stdin or the environment instead (`security.md §3` owns secret handling in general).
  - Exit with 0 when the command failed, or print errors to stdout where a script will parse them as output.

## 11. Interruptions & Notifications

- **What:** Every dialog or notification takes the person's attention away from their task. It has to be worth it, and it must never appear by surprise.
- **Basis:** GNOME HIG *Dialogs*; NN/g *Error-Message Guidelines* (severity); announcing changes to assistive technology is `accessibility.md §7`. Evidence: guideline consensus.
- **DO:**
  - Reserve modal dialogs for what blocks the task until the person decides, and open them only as the result of the person's own action.
  - Use a transient notification for information that needs no action, and a persistent one for errors and anything that needs action.
- **DON'T:**
  - Open a dialog for a simple, non-critical error that an inline message could carry.
  - Move focus or interrupt while the person is typing or reading.

## 12. UX Interactions & Trade-offs

| Tension | Guidance |
|---|---|
| Undo vs. confirmation (§3) | Undo for what can be reversed; confirmation only where it cannot; a typed confirmation only for a large, irreversible blast radius |
| Draft autosave or explicit save (§5) | Autosave where losing work is likely and saving is cheap; explicit save where a half-finished state must not take effect — and either way, a visible save state |
| Optimistic vs. pessimistic result display (§6) | Optimistic only for operations that almost never fail and can be rolled back visibly; pessimistic for payments, sends and irreversible actions |
| Human vs. machine CLI output (§10) | Human-friendly by default on a terminal; `--json`/`--plain` are the stable contract for scripts — changes to human output are not breaking, changes to those are |
| Guidance vs. efficiency (§7) | Help and defaults for the first use; shortcuts and remembered choices for the hundredth, without forcing either on the other |

## 13. Code Review Checklist
When reviewing, verify:
- [ ] The flow serves the task from the spec's context of use; a multi-step task shows the current step and what was entered before committing (§1).
- [ ] Views a person would bookmark or share have their own URL or deep link, and "back" and reload keep the person where they were (§2).
- [ ] Reversible destructive actions offer undo; irreversible ones ask for a confirmation that names the object, the consequence and the action on its button (§3).
- [ ] Error messages appear next to their cause, say what happened and how to fix it, keep the entered input and expose no internals (§4).
- [ ] No path discards the person's work — leaving with unsaved changes, a timeout, a re-login or a failed submission (§5).
- [ ] Operations beyond ~1 s show activity; beyond ~10 s show progress, an estimate and a way to cancel (§6).
- [ ] The interface shows what a step needs instead of making the person recall it (§7).
- [ ] One name per concept; buttons say what they do (§8).
- [ ] No sentence is built by concatenation; dates and numbers use locale-aware formatting; multi-locale products use CLDR plural categories and layouts that allow for translation growth (§9).
- [ ] A command-line interface has `--help`, separates stdout and stderr, offers machine-readable output, honours `NO_COLOR`/TTY detection, never requires a prompt, takes no secrets as flags and exits non-zero on failure (§10).
- [ ] Dialogs appear only after a user action and only for what blocks the task; no focus is stolen (§11).

## 14. Severity Classification

Use when raising findings in code review or the Validation Gate. Always cite this file and section (e.g., `user-experience.md §5`). BLOCK is reserved for findings where the basis is strong and the consequence is irreversible or deceives the person or a script.

| Severity | Triggers |
|----------|---------|
| 🔴 **BLOCK** | A path that silently discards the person's work — a timeout, a re-login, a navigation or a failed submission that loses entered data (§5); an irreversible destructive action with neither confirmation nor undo (§3); a command-line tool that exits with 0 when it failed (§10); a secret accepted as a command-line flag value (§10) |
| 🟡 **WARN** | An operation over ~10 s with no progress or no way to cancel (§6); an error message with no way to recover, or that discards correct input (§4); a sentence built by concatenating translatable fragments (§9); a confirmation dialog on a routine reversible action, or one with a generic "OK" button (§3); a view that does not survive reload or "back" (§2 — moderate evidence, never BLOCK); a CLI prompt with no flag equivalent, or color/animation written to a non-terminal (§10) |
| 🟢 **INFO** | Inconsistent terminology or a generic action label (§8); a missing accelerator for a frequent action (§7); a transient notification used for something that needs action (§11) |

## 15. Applying This Standard with a Limited Scope

When applying this standard to a **specific set of files or modules** (the declared Core scope), follow these constraints:

1. **Only modify files inside Core directly.** If a flow crosses views or commands outside Core, apply the Impact Zone / backlog handling below rather than editing them unconditionally.
2. **Adding undo or confirmation to a destructive action, preserving input on an error path, or an unsaved-changes warning in a file already in Core is always allowed** — they fix behavior of code already being touched.
3. **Externalizing strings or introducing a message-format library is not automatically in scope** — if the project already has one, use it for the strings this task adds; if it does not, keep new strings whole (no concatenation) and backlog the internationalization effort.
4. **Changing a CLI's flags, output or exit codes is a contract change** — make it only when the task calls for it, keep it additive, and record it in the change summary.
5. **Do not redesign a flow as a side effect** of a fix confined to one step — propose the redesign separately.

**Handling violations outside the Core scope** (per [`rules.md`](../rules.md) → Scope-Locking — Three Zones): a file is either in the **Impact Zone** (a dependent or dependency of a file already in Core, discoverable via `devflow-ctl scope impact <file>`) or **Outside**.
- **Impact Zone + one of the six closed coherence reasons** (broken caller, broken import, contract violation, duplicated logic the task just introduced, a test that now fails, a type/schema that must change together): fix it, then record `devflow-ctl scope justify <file> "<reason>"`.
- **Impact Zone without a closed coherence reason, or Outside entirely:** do not edit it. Defer it instead: `devflow-ctl backlog add <file> "<reason>" --severity {incomplete|info}` — use `incomplete` if the in-scope change is functionally incoherent without that follow-up, `info` if it is a separate improvement.

## 16. Design-Time Decisions

Record these in the spec's **Standards Applied** table, materialized in its **User Experience** section:

- **Context of use** — who the users are, their goal and main task, and the environment and interface (GUI, CLI, both), per ISO 9241-11 (§1).
- **Flow** — the steps of the main task and where the person can go back or leave (§1).
- **Addressable views** — which views get their own URL or deep link, and what state they carry (§2).
- **Destructive actions** — each one and its safeguard: undo, confirmation, or typed confirmation (§3).
- **Work protection** — what the person can lose and how it is protected: unsaved-changes warning, drafts, recovery after a session expires (§5).
- **Long operations** — which can exceed ~1 s or ~10 s, and the progress indicator, cancel action and completion notice for each (§6).
- **Locales** — the locales supported, and whether the product needs plural rules, translation room and right-to-left layout (§9).
- **Command-line contract** — commands, flags, output formats and exit codes (§10).

## 17. Implementation Self-Check

Before marking a task done:

- [ ] Every destructive action implemented has the safeguard decided at design time — undo, confirmation or typed confirmation (§3).
- [ ] Every error path keeps the person's input and shows a message that says how to recover (§4).
- [ ] No navigation, timeout, re-login or failed submission discards the person's work (§5).
- [ ] Long operations show the progress indicator decided at design time and can be cancelled (§6).
- [ ] New strings are whole sentences, dates and numbers are formatted by locale, and — in a multi-locale product — strings are externalized with CLDR plurals (§9).
- [ ] New CLI commands or flags have help, write results to stdout and diagnostics to stderr, never require a prompt, take no secrets as flags and exit non-zero on failure (§10).

## 18. Sources

- ISO 9241-110:2020, *Ergonomics of human-system interaction — Part 110: Interaction principles*. ISO.
- ISO 9241-11:2018, *Ergonomics of human-system interaction — Part 11: Usability: Definitions and concepts*. ISO.
- ISO 9241-210:2019, *Ergonomics of human-system interaction — Part 210: Human-centred design for interactive systems*. ISO.
- Nielsen, J. *10 Usability Heuristics for User Interface Design*. Nielsen Norman Group — https://www.nngroup.com/articles/ten-usability-heuristics/
- Nielsen, J. *Response Times: The 3 Important Limits* (citing Miller 1968 and Card, Robertson & Mackinlay 1991). Nielsen Norman Group — https://www.nngroup.com/articles/response-times-3-important-limits/
- Nielsen Norman Group. *Error-Message Guidelines* — https://www.nngroup.com/articles/error-message-guidelines/
- GOV.UK Design System. *Error message* — https://design-system.service.gov.uk/components/error-message/
- GNOME Human Interface Guidelines. *Dialogs* — https://developer.gnome.org/hig/patterns/feedback/dialogs.html
- Shneiderman, B. *Designing the User Interface* — the eight golden rules.
- W3C. *Web Content Accessibility Guidelines (WCAG) 2.2* — SC 2.2.5 Re-authenticating, SC 2.2.6 Timeouts — https://www.w3.org/WAI/WCAG22/Understanding/re-authenticating
- W3C. *Architecture of the World Wide Web, Volume One* — https://www.w3.org/TR/webarch/
- W3C Internationalization. *Text size in translation* — https://www.w3.org/International/articles/article-text-size/
- Unicode CLDR. *Plural Rules* — https://cldr.unicode.org/index/cldr-spec/plural-rules
- *Command Line Interface Guidelines* — https://clig.dev/
