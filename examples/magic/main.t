#include "world.h"
startup() { return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb, args)
{
    if (verb == 700) { workInput.args = args; return vhylAct(700, []); }
    return vhylAct(verb, args);
}
