# GM interface

`vhyl-rpg-gm.t` is an optional, provider-neutral adjudication boundary. Include it
after `vhyl-rpg.t`. It has no magic, parser, operating-system or model dependency.
`hosts/vhyl_gm.py` is its standard-library Python companion. No inference service
or network connection is included or enabled.

The game supplies authoritative facts and permitted choices. An adjudicator
returns a proposal. The game validates the proposal, then independently checks
mechanical eligibility when an action is attempted. Dice, costs, permissions,
retry limits and world mutations remain in the game.

```text
Game question → bounded snapshot → host adapter → proposed ruling
      ↑                                │                │
      └──────── fresh validation ←─────┴────────────────┘
                       │
                 normal game action
```

## Contract

Subclass `RpgGmQuestion` with a stable `id`, a versioned `policy`, a `revision`,
`contextData()`, `choicesData()` and `rulingReason(data)`. These hooks must be
observational. Put player requests in `prompt`; do not copy their claims into
trusted facts. Export only facts the selected adjudicator is allowed to receive.
The default validator rejects all rulings.

`rpgGmAsk(question)` returns `[1, serial, snapshot]`, where the snapshot is
`[id, policy, revision, context, choices, prompt]`. Identical pending snapshots
reuse their serial. Changed facts invalidate the previous answer.
`rpgGmSubmit(question, packet, status, data)` accepts `ruled`, `needs-input` or
`unsupported`. The latter two require an empty data list. Invalid or conflicting
answers return `blocked`; identical repeated answers return `reused`.
`rpgGmRead(question)` rechecks freshness without asking a provider or changing
state. After `needs-input`, the host or author supplies the missing facts or
changes the question revision, then asks again; it cannot overwrite the earlier
answer under the same snapshot. Clarification wording belongs to the host UI
in this first interface version. `rpgGmResolve(question, provider)` is an explicit synchronous route for
fast authored rules; previews and casting never invoke it implicitly.

Data is limited to lists, strings, signed 32-bit integers, true and null. False
is represented by null to match the engine. Maximum depth is eight, each list
has at most 128 entries, the whole value has at most 256 nodes, and aggregate
size is 8192 nodes/string characters. The separate node limit bounds scalar-event
overhead below the host event-batch limit.
Transport and policy schemas are separate: the generic envelope is version 1;
each consumer owns and versions its ruling format.

## Host bridge

`rpgGmPublishRequest` explicitly emits `rpg.gm.request`, a prefix tree of
`rpg.gm.value` scalar events, then `rpg.gm.end`. These events contain private GM
data and must not be passed to ordinary player reporting. `decode_request`
accepts exactly one such export. `Exchange.register` turns it into this JSON
object (arrays abbreviated here):

```json
{"schema":1,"epoch":"host-generation-id","serial":7,"question":"inspect","policy":"magic-1",
 "revision":0,"context":[],"choices":[],"prompt":""}
```

An `Adjudicator.adjudicate(request)` implementation returns exactly:

```json
{"schema":1,"epoch":"host-generation-id","serial":7,"question":"inspect","policy":"magic-1",
 "revision":0,"status":"ruled",
 "ruling":["inspect-material","subtle",0,"An authored observation."]}
```

`Exchange` adds a fresh random epoch on construction/reset and requires it in
every reply, so a late reply cannot match a serial reused after undo/restore.
It bounds pending requests (128 by default); call `forget(serial)` when a
request is no longer needed. `Exchange.validate` checks correlation and bounded data. `Exchange.parse` also
rejects oversized JSON and duplicate keys. The host then maps the bounded reply
into a game action; the example demonstrates this for `magic-1`. There is no
reflection, code evaluation, native object handle or model-selected action name.
The engine performs the final policy validation and stale-context check.
The demonstration transport's textual action line has a smaller 1023-byte limit
(including hex-encoded strings). An adapter using that transport must preflight
`action_line` and leave oversized replies unresolved; production hosts may use
the embedding API's scalar action interface instead. Do not truncate rulings.

The Python interface is deliberately small. A local model, an OS AI service,
a human review UI, or a remote service can implement the same protocol in a
separate package. Slow work belongs outside the game worker. Submit completed
replies on the thread that owns the session. Timeout, cancellation or provider
failure leaves the question unresolved; it never approves an action. A host
must manage timeout/cancellation and worker queue limits; this bridge is a validator,
not an asynchronous scheduler. No new Zebulon native extension is needed for
this data exchange. A platform-specific adapter can be added later without
changing game saves or casting rules.

## Lifecycle and trust

Commit ask/submit operations inside ordinary gameplay transactions. Accepted
rulings and pending questions are ordinary saved, undoable game state. Host
in-flight jobs are not saved. On undo, restore, restart or session replacement,
reset `Exchange` and cancel pending work. Its epoch check rejects late callbacks. Re-export any question that still needs adjudication.
Serials alone are not globally unique across timelines or processes.

An accepted answer remains conditional on its exact context. Content authors
must include every fact that could change a ruling, increment `revision` for
other policy-relevant changes, and keep validators independent of provider
rationale. A consumer can reject an unsafe classification or an unsupported
operation even when the transport validates. This interface cannot prove a
model's interpretation of a scene correct.

The shipped `AuthoredAdjudicator` supplies deterministic decisions now. Use the
same saved requests as an evaluation corpus when comparing future adapters:
measure valid schema rate, unsupported-case handling, classification agreement,
latency and consistency. Keep model output as proposed data until those checks
and the game's own validator accept it.
