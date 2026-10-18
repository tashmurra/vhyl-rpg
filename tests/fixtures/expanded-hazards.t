#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-skills.t>
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
    if (verb == 1807)
    {
        local patient = new RpgExpandedProfile(); patient.st = args[1]; patient.dx = 11; patient.iq = 12; patient.ht = 10;
        patient.hpAdjustment = 2; patient.fpAdjustment = 1; patient.willAdjustment = 1;
        patient.perceptionAdjustment = 2; patient.speedQuarterAdjustment = 1; patient.moveAdjustment = 1;
        patient.unspentPoints = 7; patient.earnedPoints = 7; patient.injury = 2;
        local time = rpgLedger.seconds; local draws = rpgRandom.draws;
        local value = rpgExpandedAgingSequence(patient,3,0,args[2] == 1,[11,17,10,18]);
        event('test.aging-sequence'); foreach (local score in value.scoresAfter) eventValue(score);
        foreach (local loss in value.losses) eventValue(loss);
        eventValue(value.pointLoss); eventValue(value.naturalDeath ? 1 : 0);
        eventValue(value.healthCapacity); eventValue(value.fatigueCapacity); eventValue(value.will); eventValue(value.perception);
        eventValue(value.speedQuarters); eventValue(value.move);
        event('test.aging-purity'); eventValue(patient.st); eventValue(patient.dx); eventValue(patient.iq); eventValue(patient.ht);
        eventValue(patient.unspentPoints); eventValue(patient.earnedPoints); eventValue(patient.injury);
        eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws - draws); return nil;
    }
    if (verb == 1808)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules();
        if (args[1] == 1) { patient.st = 1; patient.ht = 3; }
        patient.unspentPoints = 7; patient.earnedPoints = 7;
        local aging = new RpgExpandedAgingEvent(); aging.profile = patient; aging.calendarId = 'civil-calendar';
        aging.boundaryId = 'first-anniversary'; aging.ageYears = 50; aging.ordinal = 1; aging.reached = true;
        aging.evidence = 'First aging birthday reached'; aging.medicalTL = 3;
        if (args[1] == 2) aging.reached = nil;
        if (args[1] == 3) aging.ageYears = 49;
        rpgRandom.seed(1); local time = rpgLedger.seconds; local preview = aging.assess();
        event('test.aging-event-preview'); eventValue(preview.status); eventValue(preview.reason); eventValue(rpgRandom.draws);
        local value = aging.apply(); local repeat = aging.apply(); patient.validateFeatures();
        event('test.aging-event'); eventValue(value.status); eventValue(repeat.status);
        eventValue(patient.st); eventValue(patient.dx); eventValue(patient.iq); eventValue(patient.ht);
        eventValue(patient.dead ? 1 : 0); eventValue(patient.agingHistory.length());
        eventValue(patient.unspentPoints); eventValue(patient.earnedPoints); eventValue(rpgRandom.draws);
        eventValue(rpgLedger.seconds - time); eventValue(aging.result == nil ? 0 : aging.result.pointLoss); return nil;
    }
    if (verb == 1809)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.unspentPoints = 20; patient.earnedPoints = 20;
        local aging = new RpgExpandedAgingEvent(); aging.profile = patient; aging.calendarId = 'civil';
        aging.boundaryId = 'first-fifty'; aging.ageYears = 50; aging.ordinal = 1; aging.reached = true;
        aging.evidence = 'Aging anniversary'; rpgRandom.seed(1); aging.apply();
        local purchase = new RpgDevelopment(); purchase.id = 'later-dexterity'; purchase.profile = patient;
        purchase.kind = 'attribute'; purchase.attribute = rpgDX; purchase.target = 10; purchase.unlocked = true;
        purchase.requiresDowntime = nil; rpgDevelop(purchase);
        local youth = new RpgExpandedRejuvenation(); youth.id = 'first-youth'; youth.profile = patient;
        youth.calendarId = 'civil'; youth.oldAgeYears = 51; youth.newAgeYears = args[1] == 1 ? 50 : 49;
        youth.effectEvidence = 'Completed authored youth-restoring effect';
        local draws = rpgRandom.draws; local time = rpgLedger.seconds; local preview = youth.assess();
        event('test.youth-preview'); eventValue(preview.status); eventValue(preview.reason);
        eventValue(patient.dx); eventValue(rpgRandom.draws - draws); eventValue(rpgLedger.seconds - time);
        local value = youth.apply(); local repeat = youth.apply(); patient.validateFeatures();
        event('test.youth-result'); eventValue(value.status); eventValue(repeat.status); eventValue(value.pointGain);
        eventValue(patient.dx); eventValue(patient.unspentPoints); eventValue(patient.earnedPoints);
        eventValue(patient.rejuvenations.length()); eventValue(aging.restoredBy == youth ? 1 : 0);
        eventValue(rpgRandom.draws - draws); eventValue(rpgLedger.seconds - time);
        if (args[1] == 0)
        {
            local later = new RpgExpandedAgingEvent(); later.profile = patient; later.calendarId = 'civil';
            later.boundaryId = 'second-fifty'; later.ageYears = 50; later.ordinal = 2; later.reached = true;
            later.evidence = 'New aging anniversary after restored youth'; rpgRandom.seed(1); later.apply();
            local again = new RpgExpandedRejuvenation(); again.id = 'second-youth'; again.profile = patient;
            again.calendarId = 'civil'; again.oldAgeYears = 51; again.newAgeYears = 49;
            again.effectEvidence = 'Another completed youth-restoring effect'; local restored = again.apply();
            patient.validateFeatures(); event('test.youth-cycle'); eventValue(later.era); eventValue(restored.pointGain);
            eventValue(patient.dx); eventValue(patient.agingHistory.length()); eventValue(patient.rejuvenations.length());
        }
        return nil;
    }
    if (verb == 1830)
    {
        local value = rpgExpandedColdWeather(args[1],args[2],args[3],args[4] == 1,args[5]);
        event('test.cold-weather'); eventValue(value.checkRequired ? 1 : 0); eventValue(value.intervalSeconds);
        eventValue(value.modifier); eventValue(value.failureFatigue); return nil;
    }
    if (verb == 1831)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.iq = 15; patient.ht = 10;
        local context = new RpgExpandedColdContext(); context.profile = patient; context.temperatureEvidence = 'Observed effective temperature';
        local skill = new RpgExpandedSkill(); skill.id = 'survival'; skill.specialty = 'arctic';
        skill.attribute = rpgPerception; skill.difficulty = 1;
        local training = new RpgExpandedTraining(); training.skill = skill; training.points = args[1];
        patient.skills = [training]; context.survival = skill;
        local time = rpgLedger.seconds; local draws = rpgRandom.draws; local value = context.assess();
        event('test.cold-skill'); eventValue(value.status); eventValue(value.score);
        eventValue(value.context.skill == skill ? 1 : 0); eventValue(rpgRandom.draws - draws);
        eventValue(rpgLedger.seconds - time); return nil;
    }
    return vhylAct(verb,args);
}
