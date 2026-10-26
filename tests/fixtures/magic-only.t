#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-gm.t>
#include <vhyl-rpg-magic.t>
startup() { return vhylStart(); }
act(verb, args) { return vhylAct(verb, args); }
