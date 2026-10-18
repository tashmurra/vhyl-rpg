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
    if (verb == 1213)
    {
        local value = rpgExpandedJobEarnings(args[1],args[2] == 1,args[3],args[4],args[5]);
        event('test.job-earnings'); eventValue(value.status); eventValue(value.reason); eventValue(value.money);
        eventValue(value.nextPay); eventValue(value.consequenceRequired ? 1 : 0); return nil;
    }
    if (verb == 1214)
    {
        event('test.job-money-limits');
        try { rpgExpandedJobPercent(625,110); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        try { rpgExpandedJobPercent(1000000000,300); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        eventValue(rpgExpandedJobPercent(2000000000,100)); return nil;
    }
    if (verb == 1217)
    {
        event('test.living-cost'); eventValue(rpgExpandedLivingCost(args[1])); return nil;
    }
    if (verb == 1218)
    {
        local context = new RpgExpandedLifestyle(); context.status = args[1]; context.kind = args[2];
        context.conservativeOutfit = args[3] == 1; context.fashionBenefit = args[4] == 1;
        local value = context.assess(); event('test.lifestyle-price'); eventValue(value.money);
        eventValue(value.weight); eventValue(value.minimumWeight ? 1 : 0); return nil;
    }
    return vhylAct(verb,args);
}
