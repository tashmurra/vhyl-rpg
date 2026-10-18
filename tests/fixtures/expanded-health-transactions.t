#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
healthRoom: Room 'Recovery';
healthRules: RpgExpandedRules scaledInjuryShock = true;
healthPatient: RpgExpandedProfile rules = healthRules;
healthWound: RpgExpandedWound id = 'impact' profile = healthPatient amount = 6 location = 'face';
healthInput: object code = 0;
class HealthFixtureAction: Action
    exec(context)
    {
        if (healthInput.code == 3) healthWound.amount = 7;
        if (healthInput.code == 4)
        {
            local duplicate = new RpgExpandedWound(); duplicate.id = 'impact';
            duplicate.profile = healthPatient; duplicate.amount = 6; duplicate.apply();
        }
        else
        {
            local result = healthWound.apply(); event('test.owned-wound'); eventValue(result.status);
            if (healthInput.code == 2) throw new RpgError();
        }
        return nil;
    }
;
healthAction: HealthFixtureAction;
healthVerb: Verb code = 1610 action = healthAction label = 'wound-fixture';
modify gameMain initialRoom = healthRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1610) { healthInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1611)
    {
        event('test.wound-state'); eventValue(healthPatient.injury); eventValue(healthPatient.shock);
        eventValue(healthPatient.stunned ? 1 : 0); eventValue(healthPatient.unconscious ? 1 : 0);
        eventValue(healthPatient.posture); eventValue(healthPatient.woundSerial);
        eventValue(healthPatient.expandedWounds.length()); eventValue(healthWound.amount);
        eventValue(healthWound.health == nil ? 0 : healthWound.health.checks[1].roll);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 1612)
    {
        local result = healthWound.assess(); event('test.wound-preview'); eventValue(result.status);
        eventValue(result.assessment == nil ? 0 : result.assessment.required ? 1 : 0); return nil;
    }
    return vhylAct(verb,args);
}
