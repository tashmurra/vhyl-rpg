#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-health.t>
#include <vhyl-rpg-expanded-hazards.t>
hazardRoom: Room 'Shelter';
hazardRules: RpgExpandedRules scaledInjuryShock = true;
hazardPatient: RpgExpandedProfile rules = hazardRules injury = 2 diseaseInjury = 2;
hazardWound: RpgExpandedWound id = 'exposed-injury' profile = hazardPatient amount = 2;
hazardConditions: RpgExpandedInfectionContext untreatedDirtyWound = true;
hazardExposure: RpgExpandedInfectionExposure diseaseId = 'wound-agent' wound = hazardWound conditions = hazardConditions
    evidence = 'Observed open wound in dirty conditions';
hazardFirstDay: RpgExpandedInfectionDay id = 'first' exposure = hazardExposure careEvidence = 'No antibacterial care';
hazardSecondDay: RpgExpandedInfectionDay id = 'second' exposure = hazardExposure careEvidence = 'No antibacterial care';
immuneWound: RpgExpandedWound id = 'later-exposure' profile = hazardPatient amount = 1;
immuneExposure: RpgExpandedInfectionExposure diseaseId = 'wound-agent' wound = immuneWound conditions = hazardConditions
    evidence = 'Later exposure to the same agent';
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
        else if (code == 11 || code == 13 || code == 15)
        {
            if (hazardExposure.result == nil) rpgRandom.seed(code == 15 ? 55 : 48);
            value = hazardExposure.apply();
        }
        else if (code == 12 || code == 14)
        { immuneWound.apply(); value = immuneExposure.apply(); }
        event('test.hazard-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 2 || code == 5 || code == 7 || code == 13 || code == 14) throw new RpgError();
        return nil;
    }
;
hazardAction: HazardFixtureAction;
hazardVerb: Verb code = 1810 action = hazardAction label = 'hazard-fixture';
modify gameMain initialRoom = hazardRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return rpgDispatchTurn(tokens); }
act(verb,args)
{
    if (verb == 1810) { hazardInput.code = args[1]; return rpgDispatchAction(verb,[]); }
    if (verb == 1811)
    {
        event('test.hazard-state'); eventValue(hazardPatient.injury); eventValue(hazardPatient.diseaseInjury);
        eventValue(hazardExposure.result == nil ? 0 : hazardExposure.result.infected ? 2 : 1);
        eventValue(hazardExposure.days.length()); eventValue(hazardExposure.lockedInjury);
        eventValue(hazardExposure.ended ? 1 : 0); eventValue(hazardPatient.expandedWounds.length());
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); eventValue(hazardConditions.infectedMatter ? 1 : 0);
        return nil;
    }
    if (verb == 1812)
    {
        local record = hazardPatient.diseaseResistance('wound-agent');
        event('test.immunity-state'); eventValue(hazardPatient.diseaseResistances.length());
        eventValue(record == nil ? 0 : record.firstRoll); eventValue(record == nil ? 0 : record.immune ? 1 : 0);
        eventValue(immuneExposure.result == nil ? 0 : immuneExposure.result.immune ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(hazardPatient.injury); return nil;
    }
    return rpgDispatchAction(verb,args);
}
