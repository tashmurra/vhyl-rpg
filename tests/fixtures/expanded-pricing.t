#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-traits.t>
pricingRoom: Room 'Pricing';
modify gameMain initialRoom = pricingRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 1500)
    {
        event('test.modified-price'); eventValue(rpgExpandedSignedModifiedCost(args[1],[args[2],args[3]])); return nil;
    }
    if (verb == 1501)
    {
        event('test.self-control-price'); eventValue(rpgExpandedSelfControlCost(args[1],args[2])); return nil;
    }
    if (verb == 1502)
    {
        local trait = new RpgExpandedTrait(); trait.id = 'authored-effect'; trait.points = 10; trait.level = 2;
        trait.percentages = [-25]; event('test.trait-price-contract');
        try { trait.creationCost(); } catch (RpgExpandedError error) { eventValue(error.reason); }
        trait.approved = true; eventValue(trait.creationCost());
        local drawback = new RpgExpandedDisadvantage(); drawback.id = 'authored-drawback'; drawback.points = -5;
        drawback.approved = true; drawback.selfControlRating = 9; eventValue(drawback.creationCost());
        drawback.percentages = [-20];
        try { drawback.creationCost(); } catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    return vhylAct(verb,args);
}
