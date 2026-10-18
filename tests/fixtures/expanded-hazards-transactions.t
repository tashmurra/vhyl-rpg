#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
#include <vhyl-rpg-expanded-hazards.t>
hazardRoom: Room 'Shelter';
hazardRules: RpgExpandedRules scaledInjuryShock = true;
hazardPatient: RpgExpandedProfile rules = hazardRules injury = 2 diseaseInjury = 2;
hazardWound: RpgExpandedWound id = 'exposed-injury' profile = hazardPatient amount = 2;
hazardConditions: RpgExpandedInfectionContext untreatedDirtyWound = true;
hazardExposure: RpgExpandedInfectionExposure wound = hazardWound conditions = hazardConditions
    evidence = 'Observed open wound in dirty conditions';
hazardFirstDay: RpgExpandedInfectionDay id = 'first' exposure = hazardExposure careEvidence = 'No antibacterial care';
hazardSecondDay: RpgExpandedInfectionDay id = 'second' exposure = hazardExposure careEvidence = 'No antibacterial care';
hazardInput: object code = 0;
class HazardFixtureAction: Action
    exec(context)
    {
        local code = hazardInput.code;
        if (code == 0) { hazardWound.apply(); return nil; }
        if (code == 3) { rpgSpendTime(86400); return nil; }
        if (code == 8) hazardConditions.infectedMatter = true;
        if (code == 9) { hazardPatient.validateFeatures(); return nil; }
        local value = nil;
        if (code == 1 || code == 2 || code == 8)
        {
            if (hazardExposure.result == nil) rpgRandom.seed(5);
            value = hazardExposure.apply();
        }
        else if (code == 4 || code == 5)
        {
            if (hazardFirstDay.result == nil) rpgRandom.seed(5);
            value = hazardFirstDay.apply();
        }
        else if (code == 6 || code == 7)
        {
            if (hazardSecondDay.result == nil) rpgRandom.seed(1);
            value = hazardSecondDay.apply();
        }
        else if (code == 10) value = hazardFirstDay.assess();
        event('test.hazard-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 2 || code == 5 || code == 7) throw new RpgError();
        return nil;
    }
;
hazardAction: HazardFixtureAction;
hazardVerb: Verb code = 1810 action = hazardAction label = 'hazard-fixture';
modify gameMain initialRoom = hazardRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1810) { hazardInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1811)
    {
        event('test.hazard-state'); eventValue(hazardPatient.injury); eventValue(hazardPatient.diseaseInjury);
        eventValue(hazardExposure.result == nil ? 0 : hazardExposure.result.infected ? 2 : 1);
        eventValue(hazardExposure.days.length()); eventValue(hazardExposure.lockedInjury);
        eventValue(hazardExposure.ended ? 1 : 0); eventValue(hazardPatient.expandedWounds.length());
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); eventValue(hazardConditions.infectedMatter ? 1 : 0);
        return nil;
    }
    return vhylAct(verb,args);
}
