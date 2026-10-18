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
        local exposure = new RpgExpandedInfectionExposure(); exposure.diseaseId = 'wound-agent'; exposure.wound = wound; exposure.conditions = conditions;
        exposure.evidence = 'Observed open wound in dirty conditions';
        rpgRandom.seed(args[1]); local time = rpgLedger.seconds; local preview = exposure.assess();
        event('test.infection-preview'); eventValue(preview.status); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time);
        local result = exposure.apply(); local repeat = exposure.apply();
        local duplicate = new RpgExpandedInfectionExposure(); duplicate.diseaseId = 'wound-agent'; duplicate.wound = wound; duplicate.conditions = conditions;
        duplicate.evidence = exposure.evidence;
        event('test.infection-acquisition'); eventValue(result.infected ? 1 : 0); eventValue(result.prevented ? 1 : 0);
        eventValue(result.check == nil ? 0 : result.check.roll); eventValue(repeat.status); eventValue(duplicate.apply().reason);
        eventValue(patient.injury); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time); return nil;
    }
    if (verb == 1802)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.rules.scaledInjuryShock = true;
        patient.injury = 2; patient.diseaseInjury = 2;
        local wound = new RpgExpandedWound(); wound.profile = patient; wound.id = 'daily-wound'; wound.amount = 2; wound.apply();
        local exposure = new RpgExpandedInfectionExposure(); exposure.diseaseId = 'wound-agent'; exposure.wound = wound;
        exposure.conditions = new RpgExpandedInfectionContext(); exposure.conditions.untreatedDirtyWound = true;
        exposure.evidence = 'Observed wound exposure'; rpgRandom.seed(5); exposure.apply();
        local day = new RpgExpandedInfectionDay(); day.id = 'day-one'; day.exposure = exposure;
        day.careEvidence = 'No antibiotic care during this interval';
        local early = day.apply(); rpgSpendTime(86400); rpgRandom.seed(5);
        local time = rpgLedger.seconds; local first = day.apply(); local repeat = day.apply();
        event('test.infection-day'); eventValue(early.reason); eventValue(first.injury); eventValue(repeat.status);
        eventValue(patient.injury); eventValue(patient.diseaseInjury); eventValue(exposure.lockedInjury);
        eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws);
        local next = new RpgExpandedInfectionDay(); next.id = 'day-two'; next.exposure = exposure;
        next.careEvidence = 'No antibiotic care during this interval'; rpgSpendTime(86400); rpgRandom.seed(1);
        time = rpgLedger.seconds; local recovered = next.apply();
        event('test.infection-recovered'); eventValue(recovered.ended ? 1 : 0); eventValue(patient.injury);
        eventValue(patient.diseaseInjury); eventValue(exposure.lockedInjury); eventValue(exposure.days.length());
        eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 1803)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.rules.scaledInjuryShock = true;
        local results = []; local draws = [];
        foreach (local id in ['first','second','different'])
        {
            local wound = new RpgExpandedWound(); wound.id = id; wound.profile = patient; wound.amount = 1; wound.apply();
            local exposure = new RpgExpandedInfectionExposure(); exposure.wound = wound;
            exposure.diseaseId = id == 'different' ? 'other-agent' : 'same-agent';
            exposure.conditions = new RpgExpandedInfectionContext(); exposure.conditions.untreatedDirtyWound = true;
            exposure.evidence = 'Observed open wound exposure';
            rpgRandom.seed(id == 'first' ? args[1] : id == 'second' ? 48 : 5);
            results = results + [exposure.apply()]; draws = draws + [rpgRandom.draws];
        }
        patient.validateFeatures();
        event('test.natural-immunity');
        foreach (local result in results) { eventValue(result.immune ? 1 : 0); eventValue(result.infected ? 1 : 0); }
        foreach (local count in draws) eventValue(count);
        eventValue(patient.diseaseResistances.length()); eventValue(patient.diseaseResistance('same-agent').firstRoll);
        return nil;
    }
    if (verb == 1804)
    {
        local patient = new RpgExpandedProfile(); patient.ht = 9; patient.rules = new RpgExpandedRules(); patient.rules.scaledInjuryShock = true;
        local wound = new RpgExpandedWound(); wound.profile = patient; wound.id = 'supervised-wound'; wound.amount = 2; wound.apply();
        local exposure = new RpgExpandedInfectionExposure(); exposure.wound = wound; exposure.diseaseId = 'care-agent';
        exposure.conditions = new RpgExpandedInfectionContext(); exposure.conditions.untreatedDirtyWound = true;
        exposure.evidence = 'Observed exposure'; rpgRandom.seed(5); exposure.apply();
        local doctor = new RpgLiteProfile(); doctor.iq = 12; doctor.techLevel = 8;
        local skill = rpgLiteMakeSkill('physician',8,nil); local training = new RpgTraining(); training.skill = skill; training.points = 4;
        doctor.skills = [training]; local practice = new RpgExpandedMedicalPractice(); practice.id = 'care-practice';
        practice.physician = doctor; practice.skill = skill; practice.advancedEquipment = true;
        if (args[1] != 3) practice.admit(patient);
        rpgSpendTime(86400); if (args[1] == 3) practice.admit(patient);
        if (args[1] == 4) practice.available = nil;
        local day = new RpgExpandedInfectionDay(); day.id = 'care-day'; day.exposure = exposure; day.practice = practice;
        day.continuousCare = args[1] != 2; day.antibiotics = args[1] == 1; day.medicalTL = 8;
        day.careEvidence = 'Documented care throughout the interval';
        local time = rpgLedger.seconds; rpgRandom.seed(1); local value = day.apply();
        event('test.infection-supervision'); eventValue(value.status); eventValue(value.reason); eventValue(value.physicianBonus);
        eventValue(value.check == nil ? 0 : value.check.score); eventValue(value.ended ? 1 : 0);
        eventValue(patient.injury); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time); return nil;
    }
    if (verb == 1805)
    {
        local value = rpgExpandedAgingSchedule(args[1],args[2]); event('test.aging-schedule');
        eventValue(value.status); eventValue(value.reason); eventValue(value.maturityYears);
        foreach (local band in value.bands) foreach (local field in band) eventValue(field);
        return nil;
    }
    if (verb == 1806)
    {
        local value = rpgExpandedAgingLoss(args[1],args[2],args[3] == 1); event('test.aging-loss');
        eventValue(value.status); eventValue(value.reason); eventValue(value.loss);
        eventValue(rpgExpandedAgingModifier(args[4],args[5])); return nil;
    }
    return vhylAct(verb,args);
}
