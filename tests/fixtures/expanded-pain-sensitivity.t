#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-traits.t>
#include <vhyl-rpg-expanded-health.t>
painRoom: Room 'Recovery Ward';
modify gameMain initialRoom = painRoom;
startup() { rpgRandom.seed(5); return vhylStart(); }
painRules: RpgExpandedRules scaledInjuryShock = true;
painTrait: RpgExpandedPainSensitivity approved = true;
painProfile: RpgExpandedProfile rules = painRules traits = [painTrait];
painWound: RpgExpandedWound id = 'painful-wound' profile = painProfile amount = 2;
painInput: object code = 0;
class PainTestAction: Action
    exec(context)
    {
        if (painInput.code == 2) { painWound.amount = 1; return nil; }
        if (painInput.code == 3) { painWound.amount = 4; return nil; }
        if (painInput.code == 4) { painProfile.will = 2; return nil; }
        local value = painInput.code == 1 ? painWound.assess() : painWound.apply();
        event('test.pain-result'); eventValue(value.status); eventValue(value.reason);
        if (painInput.code == 5) throw new RpgError(); return nil;
    }
;
painAction: PainTestAction;
painVerb: Verb code = 2398 action = painAction label = 'pain wound';
act(verb,args)
{
    if (verb == 2398) { painInput.code = args[1]; return rpgDispatchAction(verb,[]); }
    if (verb == 2399)
    {
        local major = new RpgLiteContext(); major.attribute = rpgHT; major.kind = 'major-wound';
        local mental = new RpgLiteContext(); mental.attribute = rpgHT; mental.kind = 'mental-stun';
        event('test.pain-state'); eventValue(painProfile.injury); eventValue(painProfile.shock);
        eventValue(rpgRandom.draws); eventValue(painWound.health == nil ? nil : painWound.health.criedOut);
        eventValue(rpgLiteScore(painProfile,major)); eventValue(rpgLiteScore(painProfile,mental));
        eventValue(painTrait.creationCost()); eventValue(painProfile.shockAfterTurn(4)); return nil;
    }
    return rpgDispatchAction(verb,args);
}
