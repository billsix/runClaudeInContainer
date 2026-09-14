# The diversion stack & keeping the goal in sight — full rationale and mechanics

**Reference document** — the full rationale, incident, ASCII gauge, and slash-command
mechanics behind the terse "Keep the original goal in sight" and "The diversion trail" rules
in the cross-project `CLAUDE.md`. Read on demand when a task spawns a prerequisite, when a
diversion is deepening, or when learning how to operate the stack. (Relocated verbatim from
`CLAUDE.md`, 2026-09-14.)

## Keep the original goal in sight; a prerequisite is not a new project

**Before designing around a blocker, verify the blocker is real** — and if the work you
are proposing has drifted far from what I actually asked for, stop and say so instead of
building it.

This has a signature, and I have hit it (mvp, 2026-07-19). I asked for one thing —
*"doctests should run as part of the test suite"* — which was **already achieved**. From
there: a config allow-list looked like it blocked writing more doctests → that needed
runnable scripts to stop executing on import → that needed 25 files reshaped and 129
documentation references edited. Four levels down, I was drafting a repo-wide
restructure, and **nobody had checked whether the allow-list blocked anything.** It did
not: it already covered every library module in the repo. My words for it: *"we were deep
in inception, forgetting about our original goal, and then doing a huge rewrite without
keeping the goal in sight."*

The discipline:

- **Test the blocker before designing around it.** "X is blocked by Y" is a *claim*, and
  usually a cheap one to check — try the thing and watch it fail. One command would have
  ended the example above at step one. Never inherit a blocking claim from a document
  (including one you wrote) without re-verifying it; the codebase moves, and the claim may
  have been wrong when written.
- **Say the goal out loud at each level of nesting.** When a task spawns a prerequisite,
  state the chain in one line — "to do A I need B, which needs C" — because seeing the
  chain written down is what makes an absurd one visible. If the chain reaches three
  levels, that is a stop-and-report point, not a licence to keep going.
- **Scale is a signal, not a detail.** If the fix has grown to touch dozens of files while
  the request was small, that disproportion is itself evidence the framing is wrong.
  Surface it — *"this started as X and has become a restructure of Y; is that what you
  want?"* — before doing the work, not after.
- **When the goal turns out to be already met, say that first and stop.** Do not roll
  straight into the adjacent improvement you found along the way. Report it as a separate
  option I can decline.
- **A good idea found mid-drift is still drift.** The restructure above was genuinely
  reasonable *on its own merits* — that is exactly what made it seductive. Merit does not
  make it in-scope. Park it in its own task doc, say plainly that it is unrelated to the
  original ask, and get a fresh decision.

## The diversion trail — a rabbit-hole depth gauge, read bottom-up

**What this is FOR (Bill, 2026-07-19): seeing how far down the rabbit hole we are, so we
don't get so lost in the weeds that we forget our purpose and make bad decisions.** It is
**not** a to-do queue and **not** a priority list. It is a breadcrumb trail of diversions.

**Read it from the BOTTOM up.** The bottom entry is the *root purpose* — the thing we
actually set out to do. Each entry above it is a diversion from the one below. The chain
from bottom to top is the story of how we got where we are:

```
  write doctests                     <- BOTTOM = why we're here at all
   └ diverted to: dangling includes
      └ diverted to: gacalc markers
         └ diverted to: marker ID naming   <- TOP = the weeds we're currently in
```

**The failure it prevents:** on 2026-07-19 we went doctests → main guards → a layout move
→ dangling includes → markers → SHA1 ID design, and were making cross-repo architecture
decisions while the original ask (write doctests) sat untouched five levels down. Nobody
could *see* that descent, so nobody questioned whether it was worth it.

`tasks/*.md` records **the work**. This trail records **the descent** — how each thing we
are on relates to the purpose beneath it. A trail entry *points* at a task doc, never
duplicates one.

- **`/stack-push <what we're diverting to>`** — before chasing the new thing, push the
  current one. Records repo, task doc, **a concrete `resume with` action**, and **every
  unanswered question, verbatim**.
- **`/stack`** — read-only. Shows the stack top-first, verifies each entry still matches
  reality, and says what the top item means we should be doing *now*.
- **`/stack-pop`** — finished. Verifies it really is finished, archives the task doc, then
  **properly resumes** the entry underneath — restating its next action and **re-asking its
  open questions with both positions named**, since they may be many messages back.
- **`/stack-drop [n]`** — decided *not* to do it. Deliberately separate from pop: it always
  confirms, and it records *why*, because a dropped item with no reason gets re-proposed
  and re-investigated from scratch.

The stack lives at `~/.claude/stack.md` and is **global, not per-repo** — diversions cross
repos routinely (a book change in one repo turning into a generator change in another). It is
**`@`-imported into every session** (see *Auto-imported references*), so its current contents
are always in your context — you are never relying on *remembering* to open it. That makes
keeping it current non-optional: the stack is right in front of you, so a stale stack is a
visible failure, not a hidden one.

**I do NOT manage this stack — you do. That is the whole point (Bill, 2026-07-19: "I
don't want to have to remember those as commands").** The slash commands exist as manual
overrides for when I explicitly want to poke the stack, but the default is that **you keep
it current on your own, without being told**, as a normal part of how you work. Treat the
four operations below as things you *do*, not commands you wait for me to type:

- **Push, when a diversion is actually happening.** The moment we leave the current thread
  for something discovered mid-work — I ask about something you found while verifying, a
  "quick check" turns into its own investigation, a new problem is chosen — **push the
  current work first, then follow the new thread.** Do it silently as bookkeeping; a brief
  "(pushed X onto the stack)" line is enough. Do not ask permission to push.
- **Pop, when something is finished.** When work completes, archive its task doc and pop
  it **on your own**, then resume and properly restate whatever is now on top. Don't leave
  a done item sitting on the stack for me to notice.
- **Drop, only with my say-so.** Discarding an entry we won't do is the one operation that
  loses work, so this one you *do* confirm with me — but you still initiate it (notice the
  entry is dead and propose dropping it), rather than waiting for a command.
- **Surface it yourself, and reconcile at session start.** The auto-imported stack is in
  your context from the first message, so **at session start, check it against reality and
  reconcile it before doing other work** — if the "live thread" it names is not what we're
  actually doing (a prior session's thread, say), fix it (push the real current thread, move
  the stale one to a paused/deferred section) and say so briefly. Likewise, whenever the
  conversation has **drifted off the top item**, **say so unprompted** — "note: the top of the
  stack is X, but we've been on Y for a while." Catching that drift is your job, not mine; the
  stack is useless if I have to remember to ask.

**The point is depth-awareness, not "what to do now."** The trail's job is to keep the
root purpose in view, so the guidance is:

- **The most valuable line is the BOTTOM one.** When surfacing the trail, always restate
  the root purpose and the depth ("we're 4 diversions deep; the reason we started was
  X"). That single line is what stops us rabbit-holing.
- **Check the current micro-decision against the root — especially before deciding.**
  Before I ask the user to arbitrate some deep-in-the-weeds choice, look down the trail and
  ask out loud: *does this still serve the thing at the bottom, or have we lost the
  plot?* If a diversion has grown out of proportion to the purpose it was meant to serve,
  **say so** — "this started as 'write doctests' and has become a cross-repo checksum
  design; is that worth it?" That sentence is the entire reason this trail exists.
- **When recommending a next action, prefer the entry closest to the ROOT that is
  actionable** — climbing back *down* toward the purpose, not deeper into the newest
  tangent. Phrase it as a recommendation, never a present-tense fact, and give **one**
  recommendation, not a menu (that hands the user the sorting the trail is meant to do for
  him). I got this exactly wrong on 2026-07-19: asserted "what we should be doing now:
  <newest tangent>", then contradicted it, then handed the user a list to arbitrate.

**Two things must survive a push:** the concrete next action, and the unanswered
questions, verbatim. A vague "continue the doctest work" is a failed entry; so is one that
drops a question I never answered.

**When in doubt, err toward pushing.** An extra stack entry costs a few lines; a lost
thread costs a whole investigation redone. If you are unsure whether a tangent is big
enough to push, push it.
