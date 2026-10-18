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
    if (verb == 2289)
    {
        local value = rpgExpandedRadiationOutcome(args[1],args[2],args[3],args[4]);
        event('test.radiation-table'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.modifier); eventValue(value.effect);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2290)
    {
        event('test.radiation-decay'); eventValue(rpgExpandedRadiationRemainingTenths(args[1],args[2]));
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 1993)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.fatigue = 10;
        local fighter = new RpgLiteFighter(); fighter.profile = patient;
        local attacker = new RpgLiteFighter(); attacker.profile = new RpgLiteProfile();
        attacker.weapon = rpgLiteMakeWeapon('punch',10); local request = new RpgLiteManeuver();
        local gate = new RpgExpandedEffort(); gate.id = 'defense-collapse'; gate.profile = patient;
        gate.evidence = 'Failed effort before the attempted defense';
        rpgRandom.seed(9); gate.apply(); local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
        event('test.collapse-defense'); eventValue(patient.unconscious ? 1 : 0);
        eventValue(rpgLiteDefenseScore(fighter,attacker,request,'dodge'));
        eventValue(rpgLiteDefenseScore(fighter,attacker,request,'block'));
        eventValue(rpgLiteDefenseScore(fighter,attacker,request,'parry'));
        eventValue(rpgRandom.draws - draws); eventValue(rpgLedger.seconds - clock);
        rpgLiteRest(patient,600,true,true,nil,true);
        event('test.recovered-defense'); eventValue(patient.fatigue); eventValue(patient.exhaustionCollapsed ? 1 : 0);
        eventValue(rpgLiteDefenseScore(fighter,attacker,request,'dodge'));
        eventValue(rpgRandom.draws - draws); eventValue(rpgLedger.seconds - clock); return nil;
    }

    if (verb == 1991)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules();
        patient.rules.expandedFatigueStrength = true; patient.fatigue = 7;
        local skill = new RpgLiteSkill(); skill.attribute = rpgST; skill.defaultPenalty = -4;
        local context = new RpgLiteContext(); context.skill = skill;
        local draws = rpgRandom.draws; local clock = rpgLedger.seconds; local reason = nil;
        try { rpgLiteCheck(patient,context); }
        catch (RpgExpandedError error) { reason = error.reason; }
        event('test.fatigue-strength-default'); eventValue(reason); eventValue(patient.fatigue);
        eventValue(rpgRandom.draws - draws); eventValue(rpgLedger.seconds - clock); return nil;
    }

    if (verb == 1990)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules();
        patient.rules.expandedFatigueStrength = args[5] == 1;
        patient.st = args[1]; patient.ht = args[2]; patient.fatigue = args[3]; patient.injury = args[4];
        local context = new RpgLiteContext(); context.attribute = rpgST;
        local skill = new RpgLiteSkill(); skill.attribute = rpgDX; skill.difficulty = 0;
        local training = new RpgTraining(); training.skill = skill; training.points = 1; patient.skills = [training];
        local relative = new RpgExpandedSkillContext(); relative.skill = skill; relative.rollAttribute = rpgST;
        local fixed = new RpgExpandedSkillContext(); fixed.skill = skill; fixed.fixedBase = 10;
        local defender = new RpgLiteFighter(); defender.profile = patient;
        local attacker = new RpgLiteFighter(); attacker.profile = new RpgLiteProfile();
        attacker.weapon = rpgLiteMakeWeapon('punch',10);
        local request = new RpgLiteManeuver();
        local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
        event('test.fatigue-strength'); eventValue(rpgLiteScore(patient,context));
        eventValue(rpgLiteScore(patient,relative)); eventValue(rpgLiteScore(patient,fixed));
        eventValue(patient.st); eventValue(patient.maxHP); eventValue(patient.basicLiftHundredths());
        eventValue(patient.move()); eventValue(rpgLiteDefenseScore(defender,attacker,request,'dodge'));
        eventValue(rpgRandom.draws - draws); eventValue(rpgLedger.seconds - clock); return nil;
    }

    if (verb == 1971)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.dx = 11;
        patient.fatigue = args[1]; patient.injury = args[2];
        local fighter = new RpgLiteFighter(); fighter.profile = patient;
        local other = new RpgLiteFighter(); other.profile = new RpgLiteProfile();
        local battle = new RpgLiteBattle(); battle.fighters = [fighter,other]; battle.begin();
        local request = new RpgExpandedHealthManeuver(); request.kind = args[4]; request.movement = args[5];
        local gate = new RpgExpandedActionGate(); gate.id = 'maneuver'; gate.profile = patient;
        gate.purpose = request.kind == 'nothing' ? 'do-nothing' : 'action'; gate.evidence = 'One maneuver';
        request.healthGate = gate;
        rpgRandom.seed(args[3]); local clock = rpgLedger.seconds;
        local value = battle.step(fighter,request);
        event('test.health-maneuver'); eventValue(value.status); eventValue(value.reason); eventValue(value.outcome);
        eventValue(patient.unconscious ? 1 : 0); eventValue(patient.exhaustionCollapsed ? 1 : 0);
        eventValue(patient.effortHistory.length()); eventValue(rpgRandom.draws);
        eventValue(battle.index); eventValue(rpgLedger.seconds - clock);
        if (value.status == 'resolved')
        {
            local idle = new RpgLiteManeuver(); battle.step(other,idle);
            local repeat = battle.step(fighter,request);
            event('test.health-maneuver-repeat'); eventValue(repeat.status); eventValue(repeat.reason);
            eventValue(patient.effortHistory.length()); eventValue(rpgRandom.draws); eventValue(battle.index);
            eventValue(rpgLedger.seconds - clock);
        }
        return nil;
    }

    if (verb == 1970)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules();
        patient.fatigue = args[1]; patient.injury = args[2];
        local gate = new RpgExpandedActionGate(); gate.id = 'turn'; gate.profile = patient;
        gate.purpose = args[4]; gate.evidence = 'One authored turn';
        rpgRandom.seed(args[3]); local clock = rpgLedger.seconds; local preview = gate.assess();
        event('test.action-gate-preview'); eventValue(preview.status); eventValue(rpgRandom.draws);
        eventValue(patient.effortHistory.length()); eventValue(rpgLedger.seconds - clock);
        local value = gate.apply(); local repeat = gate.apply(); patient.validateFeatures();
        event('test.action-gate'); eventValue(value.allowed ? 1 : 0); eventValue(value.reason);
        eventValue(value.check == nil ? 0 : value.check.roll);
        eventValue(value.consciousnessCheck == nil ? 0 : value.consciousnessCheck.roll);
        eventValue(patient.unconscious ? 1 : 0); eventValue(patient.exhaustionCollapsed ? 1 : 0);
        eventValue(patient.cardiacHistory.length()); eventValue(rpgRandom.draws);
        eventValue(repeat.status); eventValue(repeat.allowed ? 1 : 0);
        eventValue(repeat.consciousnessCheck == nil ? 0 : repeat.consciousnessCheck.roll);
        eventValue(rpgLedger.seconds - clock); return nil;
    }

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
    if (verb == 1832)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.fatigue = 2; patient.temperatureFatigue = 2;
        local exposure = new RpgExpandedColdExposure(); exposure.id = 'winter-watch'; exposure.profile = patient;
        exposure.temperatureEvidence = 'Observed freezing temperature, still air'; exposure.start();
        local interval = new RpgExpandedColdInterval(); interval.id = 'first'; interval.exposure = exposure;
        rpgRandom.seed(5); local early = interval.apply(); rpgSpendTime(1800); local time = rpgLedger.seconds;
        local value = interval.apply(); local repeat = interval.apply(); patient.validateFeatures();
        event('test.cold-interval'); eventValue(early.reason); eventValue(value.fatigue); eventValue(repeat.status);
        eventValue(patient.fatigue); eventValue(patient.temperatureFatigue); eventValue(exposure.lockedFatigue);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time);
        local blocked = exposure.finish(true,nil,'Shelter without heat');
        local ended = exposure.finish(true,true,'Shelter and a working heat source'); patient.validateFeatures();
        event('test.cold-shelter'); eventValue(blocked.reason); eventValue(ended.status);
        eventValue(patient.fatigue); eventValue(patient.temperatureFatigue); eventValue(exposure.lockedFatigue);
        eventValue(patient.coldExposure == nil ? 1 : 0); eventValue(rpgLedger.seconds - time); return nil;
    }
    if (verb == 1833)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.rules.scaledInjuryShock = true;
        patient.fatigue = args[1]; patient.temperatureFatigue = 2; patient.injury = 2; patient.temperatureInjury = 2;
        local exposure = new RpgExpandedColdExposure(); exposure.id = 'overflow-watch'; exposure.profile = patient;
        exposure.temperatureEvidence = 'Observed freezing conditions'; exposure.start(); rpgSpendTime(1800);
        local interval = new RpgExpandedColdInterval(); interval.id = 'first'; interval.exposure = exposure;
        rpgRandom.seed(args[2]); local time = rpgLedger.seconds; local value = interval.apply(); patient.validateFeatures();
        event('test.cold-overflow'); eventValue(value.fatigue); eventValue(value.injury); eventValue(patient.fatigue);
        eventValue(patient.injury); eventValue(patient.temperatureFatigue); eventValue(patient.temperatureInjury);
        eventValue(patient.fatigueCollapse ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time);
        interval.apply(); exposure.finish(true,true,'Adequate shelter and heat'); patient.validateFeatures();
        event('test.cold-overflow-shelter'); eventValue(patient.fatigue); eventValue(patient.injury);
        eventValue(patient.temperatureFatigue); eventValue(patient.temperatureInjury); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 1850)
    {
        local value = rpgExpandedHeatExertion(args[1],args[2]); event('test.heat-exertion');
        eventValue(value.status); eventValue(value.reason); eventValue(value.extraFatigue); return nil;
    }
    if (verb == 1851)
    {
        local time = rpgLedger.seconds; local draws = rpgRandom.draws;
        local value = rpgExpandedHeatOutcome(args[1],args[2],args[3] == 0 ? nil : args[3]);
        event('test.heat-outcome'); eventValue(value.fatigue); eventValue(value.heatStroke ? 1 : 0);
        eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws - draws); return nil;
    }
    if (verb == 1852)
    {
        local time = rpgLedger.seconds; local draws = rpgRandom.draws;
        local value = rpgExpandedThermalShock(args[1] == 1,args[2],args[3]);
        event('test.thermal-shock'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.ordinaryCold ? 1 : 0); eventValue(value.intervalSeconds); eventValue(value.fatigue);
        eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws - draws); return nil;
    }
    if (verb == 1853)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.rules.scaledInjuryShock = true;
        patient.fatigue = args[1]; patient.temperatureFatigue = 2;
        local exposure = new RpgExpandedImmersion(); exposure.id = 'icy-water'; exposure.profile = patient;
        exposure.evidence = 'Sudden icy immersion without a waterproof dry suit; breathing handled separately';
        local started = exposure.start(); local repeatStart = exposure.start();
        local interval = new RpgExpandedImmersionInterval(); interval.id = 'minute-one'; interval.exposure = exposure;
        rpgRandom.seed(args[2]); local early = interval.apply(); rpgSpendTime(60);
        local time = rpgLedger.seconds; local preview = interval.assess(); local value = interval.apply();
        event('test.immersion-interval'); eventValue(started.status); eventValue(repeatStart.status);
        eventValue(early.reason); eventValue(preview.status); eventValue(value.status); eventValue(value.reason);
        eventValue(value.fatigue); eventValue(patient.fatigue); eventValue(patient.temperatureFatigue);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time);
        if (value.status != 'resolved') return nil;
        local repeated = interval.apply(); local beforeExit = exposure.warm(true,true,'Warm shelter');
        local exited = exposure.leave('Removed from the icy water');
        local cold = new RpgExpandedColdExposure(); cold.id = 'post-immersion'; cold.profile = patient;
        cold.temperatureEvidence = 'Freezing air after rescue'; local coldStart = cold.start();
        local noHeat = exposure.warm(true,nil,'Shelter without heat');
        local warmed = exposure.warm(true,true,'Shelter and external heat');
        patient.validateFeatures();
        event('test.immersion-recovery'); eventValue(repeated.status); eventValue(beforeExit.reason);
        eventValue(exited.status); eventValue(coldStart.status); eventValue(noHeat.reason); eventValue(warmed.status);
        eventValue(patient.fatigue); eventValue(patient.temperatureFatigue); eventValue(exposure.lockedFatigue);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time); return nil;
    }
    if (verb == 1854)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules();
        local exposure = new RpgExpandedImmersion(); exposure.id = 'water'; exposure.profile = patient;
        exposure.evidence = 'Icy immersion'; exposure.start();
        local cold = new RpgExpandedColdExposure(); cold.id = 'duplicate'; cold.profile = patient;
        cold.temperatureEvidence = 'Freezing conditions'; local blocked = cold.start();
        local climate = new RpgLiteClimate(); climate.profile = patient;
        local rejected = nil;
        try { climate.advance(60); } catch (RpgExpandedError error) { rejected = true; }
        event('test.immersion-conflict'); eventValue(blocked.reason); eventValue(rejected ? 1 : 0);
        eventValue(climate.elapsed); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 1855)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules();
        patient.rules.scaledInjuryShock = args[3] == 1; patient.fatigue = args[1];
        patient.temperatureFatigue = 2; patient.injury = args.length() > 3 ? args[4] : 2; patient.temperatureInjury = 2;
        local exposure = new RpgExpandedImmersion(); exposure.id = 'overflow'; exposure.profile = patient;
        exposure.evidence = 'Unprotected icy immersion'; exposure.start(); rpgSpendTime(60);
        local interval = new RpgExpandedImmersionInterval(); interval.id = 'one'; interval.exposure = exposure;
        rpgRandom.seed(args[2]); local value = interval.apply();
        patient.validateFeatures();
        event('test.immersion-overflow'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.requestedFatigue); eventValue(value.fatigue); eventValue(value.injury);
        eventValue(patient.fatigue); eventValue(patient.injury); eventValue(patient.temperatureFatigue);
        eventValue(patient.temperatureInjury); eventValue(patient.fatigueCollapse ? 1 : 0);
        eventValue(value.wounds.length()); eventValue(rpgRandom.draws);
        event('test.immersion-terminal'); eventValue(patient.dead ? 1 : 0); eventValue(patient.mortal ? 1 : 0);
        if (value.status == 'resolved')
        {
            interval.apply(); exposure.leave('Rescued'); exposure.warm(true,true,'Shelter and heat'); patient.validateFeatures();
            event('test.immersion-overflow-recovery'); eventValue(patient.fatigue); eventValue(patient.injury);
            eventValue(patient.temperatureFatigue); eventValue(patient.temperatureInjury); eventValue(rpgRandom.draws);
        }
        return nil;
    }
    if (verb == 1890)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.rules.scaledInjuryShock = true;
        patient.fatigue = args[1]; patient.injury = 2;
        local exposure = new RpgExpandedAirlessExposure(); exposure.id = 'air-test'; exposure.profile = patient;
        exposure.evidence = 'Complete deprivation with no breath reserve or exceptional physiology'; exposure.start();
        local second = new RpgExpandedAirlessSecond(); second.id = 'one'; second.exposure = exposure;
        local early = second.apply(); rpgSpendTime(1); rpgRandom.seed(args[2]); local value = second.apply();
        local repeated = second.apply(); patient.validateFeatures();
        event('test.airless-second'); eventValue(early.reason); eventValue(value.fatigue); eventValue(value.injury);
        eventValue(patient.fatigue); eventValue(patient.injury); eventValue(patient.unconscious ? 1 : 0);
        eventValue(patient.airClock); eventValue(repeated.status); eventValue(rpgRandom.draws);
        local rescue = exposure.resumeAir('Air supply restored'); local repeatRescue = exposure.resumeAir('Air supply restored');
        patient.validateFeatures(); event('test.airless-rescue'); eventValue(rescue.status); eventValue(repeatRescue.status);
        eventValue(patient.airClock); eventValue(patient.iq); eventValue(patient.fatigue); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 1891)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.fpAdjustment = 990;
        local exposure = new RpgExpandedAirlessExposure(); exposure.id = 'duration-test'; exposure.profile = patient;
        exposure.evidence = 'Complete deprivation, large fatigue capacity, no breathing exemption'; exposure.start();
        local key = ''; rpgRandom.seed(5);
        for (local count = 0; count < args[1]; count += 1)
        {
            key += 's'; rpgSpendTime(1); local second = new RpgExpandedAirlessSecond();
            second.id = key; second.exposure = exposure; second.apply();
        }
        local before = rpgRandom.draws; local preview = exposure.assessAir('Fresh air');
        local value = exposure.resumeAir('Fresh air'); exposure.resumeAir('Fresh air'); patient.validateFeatures();
        event('test.airless-duration'); eventValue(preview.status); eventValue(value.status); eventValue(value.reason);
        eventValue(patient.fatigue); eventValue(patient.airClock); eventValue(patient.iq); eventValue(patient.dead ? 1 : 0);
        eventValue(value.intelligenceLoss); eventValue(before); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 1892)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules();
        local exposure = new RpgExpandedAirlessExposure(); exposure.id = 'owned'; exposure.profile = patient;
        exposure.evidence = 'No available air'; exposure.start(); local legacy = nil; local rest = nil;
        try { rpgLiteSuffocate(patient,1,nil); } catch (RpgExpandedError error) { legacy = true; }
        try { rpgLiteRest(patient,600,true,true,nil,true); } catch (RpgExpandedError error) { rest = true; }
        event('test.airless-conflict'); eventValue(legacy ? 1 : 0); eventValue(rest ? 1 : 0);
        eventValue(patient.fatigue); eventValue(patient.airClock); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 1893)
    {
        local value = rpgExpandedResuscitationProcedure(args[1],args[2],args[3] == 1,args[4] == 1,args[5]);
        event('test.resuscitation-procedure'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.modifier); eventValue(value.seconds); return nil;
    }
    if (verb == 1920)
    {
        local value = rpgExpandedCardiacHealth(args[1],args[2],args[3] == 1);
        event('test.cardiac-health'); eventValue(value.totalInjury); eventValue(value.addedInjury); return nil;
    }
    if (verb == 1921)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules();
        patient.ht = args[1]; patient.fatigue = 3; patient.injury = args[2];
        patient.temperatureFatigue = 1; patient.temperatureInjury = 1;
        if (args[3] != 'none') { local trait = new RpgLiteTrait(); trait.id = args[3]; patient.traits = [trait]; }
        local arrest = new RpgExpandedCardiacArrest(); arrest.id = 'arrest'; arrest.profile = patient;
        arrest.evidence = 'Confirmed affliction trigger'; local started = arrest.start(); local repeated = arrest.start();
        patient.validateFeatures();
        event('test.cardiac-onset'); eventValue(started.prevented ? 1 : 0); eventValue(started.fatigueAdded);
        eventValue(patient.fatigue); eventValue(patient.injury); eventValue(patient.unconscious ? 1 : 0);
        eventValue(arrest.deadline == nil ? nil : arrest.deadline - arrest.startedAt); eventValue(repeated.status);
        eventValue(patient.temperatureFatigue); eventValue(patient.temperatureInjury); eventValue(rpgRandom.draws);
        if (started.prevented)
        {
            local rejected = arrest.expire(); event('test.cardiac-immune'); eventValue(rejected.reason);
            eventValue(patient.cardiacArrest == nil ? 0 : 1); return nil;
        }
        local rest = nil;
        try { rpgLiteRest(patient,60,true,true,nil,true); } catch (RpgExpandedError error) { rest = true; }
        rpgSpendTime(args[1] * 20 - 1); local early = arrest.expire(); rpgSpendTime(1);
        local value = arrest.expire(); local repeat = arrest.expire(); patient.validateFeatures();
        event('test.cardiac-expiry'); eventValue(rest ? 1 : 0); eventValue(early.reason); eventValue(value.injuryAdded);
        eventValue(patient.injury); eventValue(patient.dead ? 1 : 0); eventValue(patient.cardiacArrest == nil ? 0 : 1);
        eventValue(repeat.status); eventValue(patient.temperatureFatigue); eventValue(patient.temperatureInjury);
        eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 1922)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.ht = args[1]; patient.injury = args[2];
        local arrest = new RpgExpandedCardiacArrest(); arrest.id = 'treated'; arrest.profile = patient; arrest.evidence = 'Confirmed trigger'; arrest.start();
        local healer = new RpgLiteProfile(); healer.iq = 14; healer.techLevel = args[4];
        local skill = new RpgLiteSkill(); skill.id = args[3]; skill.attribute = rpgIQ;
        skill.difficulty = skill.id == 'first-aid' ? 0 : 2; skill.techLevel = args[4];
        local training = new RpgTraining(); training.skill = skill; training.points = 1; healer.skills = [training];
        local attempt = new RpgExpandedCardiacResuscitation(); attempt.id = 'one'; attempt.arrest = arrest;
        attempt.healer = healer; attempt.skill = skill; attempt.careEvidence = 'One uninterrupted minute with appropriate equipment';
        rpgRandom.seed(args[5]); local time = rpgLedger.seconds; local preview = attempt.assess();
        local value = attempt.apply(); local repeat = attempt.apply(); patient.validateFeatures();
        event('test.cardiac-treatment'); eventValue(preview.status); eventValue(value.status); eventValue(value.reason);
        eventValue(value.check == nil ? nil : value.check.score); eventValue(value.revived ? 1 : 0);
        eventValue(value.injuryAdded); eventValue(patient.injury); eventValue(patient.fatigue);
        eventValue(patient.cardiacArrest == nil ? 0 : 1); eventValue(repeat.status);
        eventValue(arrest.attempts.length()); eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws);
        if (value.status == 'resolved' && !value.revived)
        {
            local retry = new RpgExpandedCardiacResuscitation(); retry.id = 'two'; retry.arrest = arrest;
            retry.healer = healer; retry.skill = skill; retry.careEvidence = attempt.careEvidence;
            rpgRandom.seed(1); local next = retry.apply(); patient.validateFeatures();
            event('test.cardiac-retry'); eventValue(next.status); eventValue(next.revived ? 1 : 0);
            eventValue(patient.injury); eventValue(arrest.attempts.length()); eventValue(rpgLedger.seconds - time);
            eventValue(rpgRandom.draws); return nil;
        }
        return nil;
    }
    if (verb == 1940)
    {
        local time = rpgLedger.seconds; local draws = rpgRandom.draws;
        local value = rpgExpandedExhaustionOutcome(args[1],args[2],args[3] == 1,args[4],args[5],args[6],args[7],args[8]);
        event('test.exhaustion-outcome'); eventValue(value.allowed ? 1 : 0); eventValue(value.incapacitated ? 1 : 0);
        eventValue(value.unconscious ? 1 : 0); eventValue(value.cardiacTrigger ? 1 : 0); eventValue(value.reason);
        eventValue(value.check == nil ? 0 : 1); eventValue(value.healthCheck == nil ? 0 : 1);
        eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws - draws); return nil;
    }
    if (verb == 1941)
    {
        event('test.low-fatigue-value'); eventValue(rpgExpandedLowFatigueValue(args[1],args[2],args[3])); return nil;
    }
    if (verb == 1950)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.fatigue = 10;
        if (args[2] != 'none') { local trait = new RpgLiteTrait(); trait.id = args[2]; patient.traits = [trait]; }
        local effort = new RpgExpandedEffort(); effort.id = 'open-door'; effort.profile = patient; effort.evidence = 'Attempt to open a door';
        rpgRandom.seed(args[1]); local time = rpgLedger.seconds; effort.assess();
        event('test.effort-preview'); eventValue(patient.fatigue); eventValue(patient.exhaustionCollapsed ? 1 : 0);
        eventValue(patient.cardiacHistory.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time);
        local value = effort.apply(); local repeat = effort.apply(); patient.validateFeatures();
        event('test.effort-owned'); eventValue(value.allowed ? 1 : 0); eventValue(value.incapacitated ? 1 : 0);
        eventValue(value.unconscious ? 1 : 0); eventValue(value.cardiacTrigger ? 1 : 0); eventValue(patient.fatigue);
        eventValue(patient.unconscious ? 1 : 0); eventValue(patient.exhaustionCollapsed ? 1 : 0);
        eventValue(patient.cardiacArrest == nil ? 0 : 1); eventValue(patient.cardiacHistory.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds - time); eventValue(repeat.status); return nil;
    }
    if (verb == 1951)
    {
        local patient = new RpgExpandedProfile(); patient.rules = new RpgExpandedRules(); patient.fatigue = 10;
        local effort = new RpgExpandedEffort(); effort.id = 'first'; effort.profile = patient; effort.evidence = 'First effort';
        rpgRandom.seed(9); effort.apply(); local before = rpgRandom.draws; local legacy = rpgLiteCanAct(patient,nil);
        local second = new RpgExpandedEffort(); second.id = 'second'; second.profile = patient; second.evidence = 'Second effort';
        local blocked = second.apply();
        event('test.effort-collapse'); eventValue(legacy ? 1 : 0); eventValue(blocked.allowed ? 1 : 0);
        eventValue(blocked.reason); eventValue(patient.unconscious ? 1 : 0); eventValue(rpgRandom.draws - before);
        rpgLiteRest(patient,600,true,true,nil,true); effort.apply();
        local recovered = new RpgExpandedEffort(); recovered.id = 'third'; recovered.profile = patient; recovered.evidence = 'Recovered effort';
        local value = recovered.apply(); patient.validateFeatures();
        event('test.effort-recovery'); eventValue(patient.fatigue); eventValue(patient.exhaustionCollapsed ? 1 : 0);
        eventValue(patient.unconscious ? 1 : 0); eventValue(value.allowed ? 1 : 0);
        eventValue(patient.effortHistory.length()); eventValue(rpgRandom.draws); return nil;
    }
    return vhylAct(verb,args);
}
