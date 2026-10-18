#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-characters.t>
expandedRoom: Room 'Workshop';
expandedRules: RpgExpandedRules;
expandedHero: RpgExpandedProfile actor = player rules = expandedRules;
startup() { return vhylStart(); }
act(verb, args) { return vhylAct(verb, args); }
modify gameMain initialRoom = expandedRoom;
