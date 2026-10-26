#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-gm.t>
startup() { return vhylStart(); }
act(verb, args) { return vhylAct(verb, args); }
