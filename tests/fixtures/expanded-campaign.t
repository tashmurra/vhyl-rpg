#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-campaign.t>
campaignRoom: Room 'Registry';
modify gameMain initialRoom = campaignRoom;
startup() { return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1151)
    {
        local access = new RpgExpandedLegalAccess(); access.controlRating = 3; access.legality = 2;
        access.legitimateNeed = true;
        local value = access.assess(); event('test.campaign-minimal');
        eventValue(value.reason); eventValue(value.licenseEligible); return nil;
    }
    return vhylAct(verb,args);
}
