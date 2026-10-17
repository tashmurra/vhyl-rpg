/* The rules layer needs no dialogue, preview, or language module. */
#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
hall: Room 'Hall';
goal: RpgChallenge id = 'entry';
entry: RpgApproach id = 'entry' challenge = goal automatic = true;
visitor: RpgProfile actor = player;
entrySlot: RpgAttempt profile = visitor approach = entry;
entryAction: Action
    exec(c) { return rpgPublish(rpgResolve(visitor, entry)); }
;
vEntry: Verb code = 100 action = entryAction label = 'entry';
modify gameMain initialRoom = hall;
startup() { return vhylStart(); }
act(verb, args) { return vhylAct(verb, args); }
