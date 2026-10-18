#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
#include <vhyl-rpg-expanded-hazards.t>
hazardRoom: Room 'Shelter';
modify gameMain initialRoom = hazardRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 1800)
    {
        local context = new RpgExpandedInfectionContext(); context.infectedMatter = args[2] == 1;
        context.specialLocale = args[3] == 1; context.antibiotics = args[4] == 1;
        context.medicalTL = args[5]; context.criticalTreatmentFailure = args[6] == 1;
        context.untreatedDirtyWound = args[7] == 1;
        local time = rpgLedger.seconds; local draws = rpgRandom.draws;
        local value = args[1] == 0 ? context.assessAcquisition() : context.assessTypicalProgression();
        event('test.infection-context'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.modifier); eventValue(value.checkRequired ? 1 : 0); eventValue(value.prevented ? 1 : 0);
        eventValue(value.intervalSeconds); eventValue(value.failureInjury); eventValue(value.successEndsInfection ? 1 : 0);
        eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws - draws); return nil;
    }
    if (verb == 1801)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.rules.scaledInjuryShock = true;
        local wound = new RpgExpandedWound(); wound.profile = patient; wound.id = 'exposed-wound'; wound.amount = 2; wound.apply();
        local conditions = new RpgExpandedInfectionContext(); conditions.untreatedDirtyWound = true;
        conditions.antibiotics = args[2] == 1;
        local exposure = new RpgExpandedInfectionExposure(); exposure.wound = wound; exposure.conditions = conditions;
        exposure.evidence = 'Observed open wound in dirty conditions';
        rpgRandom.seed(args[1]); local time = rpgLedger.seconds; local preview = exposure.assess();
        event('test.infection-preview'); eventValue(preview.status); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time);
        local result = exposure.apply(); local repeat = exposure.apply();
        local duplicate = new RpgExpandedInfectionExposure(); duplicate.wound = wound; duplicate.conditions = conditions;
        duplicate.evidence = exposure.evidence;
        event('test.infection-acquisition'); eventValue(result.infected ? 1 : 0); eventValue(result.prevented ? 1 : 0);
        eventValue(result.check == nil ? 0 : result.check.roll); eventValue(repeat.status); eventValue(duplicate.apply().reason);
        eventValue(patient.injury); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time); return nil;
    }
    return vhylAct(verb,args);
}
