#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-health.t>
healthRoom: Room 'Recovery';
healthRules: RpgExpandedRules scaledInjuryShock = true;
healthPatient: RpgExpandedProfile rules = healthRules;
healthWound: RpgExpandedWound id = 'impact' profile = healthPatient amount = 6 location = 'face';
healthHeld: RpgLiteItem id = 'held' ready = true weight = 100;
healthWorn: RpgLiteItem id = 'worn' ready = true worn = true weight = 200;
healthPacked: RpgLiteItem id = 'packed' weight = 300;
healthFighter: RpgLiteFighter profile = healthPatient aimWeapon = healthHeld aimSeconds = 2;
healthInput: object code = 0;
class HealthFixtureAction: Action
    exec(context)
    {
        if (healthInput.code == 5 || healthInput.code == 6 || healthInput.code == 7 || healthInput.code == 8)
        {
            healthPatient.equipment = [healthHeld,healthWorn,healthPacked];
            if (healthInput.code != 7) healthWound.dropDestination = 'floor';
        }
        if (healthInput.code == 8) healthPatient.ht = 15;
        if (healthInput.code == 9) healthWound.dropDestination = 'different-floor';
        if (healthInput.code == 10)
        {
            /* Isolate inventory continuation after an authored later recovery. */
            healthPatient.unconscious = nil;
            local pickup = new RpgExpandedEquipmentStorage(); pickup.profile = healthPatient;
            pickup.item = healthHeld; pickup.accessible = true; pickup.move(); healthHeld.ready = true;
        }
        if (healthInput.code == 3) healthWound.amount = 7;
        if (healthInput.code == 4)
        {
            local duplicate = new RpgExpandedWound(); duplicate.id = 'impact';
            duplicate.profile = healthPatient; duplicate.amount = 6; duplicate.apply();
        }
        else
        {
            local result = healthWound.apply(); event('test.owned-wound'); eventValue(result.status);
            if (healthInput.code == 2 || healthInput.code == 6) throw new RpgError();
        }
        return nil;
    }
;
healthAction: HealthFixtureAction;
healthVerb: Verb code = 1610 action = healthAction label = 'wound-fixture';
limbPatient: RpgExpandedProfile rules = healthRules bodyParts = [limbArm,limbHand] equipment = [limbHeld,limbShield];
limbArm: RpgExpandedBodyPart id = 'arm' profile = limbPatient;
limbHand: RpgExpandedBodyPart id = 'hand' kind = 'hand' profile = limbPatient parent = limbArm;
limbHeld: RpgLiteWeapon id = 'held' ready = true bodySupports = [limbHand];
limbShield: RpgLiteItem id = 'shield' ready = true worn = true db = 3 bodySupports = [limbArm];
limbWound: RpgExpandedWound id = 'limb-impact' profile = limbPatient amount = 8 location = 'arm'
    bodyPart = limbArm dropDestination = 'floor';
limbOtherArm: RpgExpandedBodyPart id = 'other-arm' profile = limbPatient;
limbOtherHand: RpgExpandedBodyPart id = 'other-hand' kind = 'hand' profile = limbPatient parent = limbOtherArm;
limbTwoHandMode: RpgLiteAttackMode hands = 2 requiresTwoHands = true minimumST = 10;
class LimbFixtureAction: Action
    exec(context)
    {
        if (healthInput.code == 2) { limbWound.amount = 12; limbWound.severing = true; }
        if (healthInput.code == 3) { limbWound.bodyPart = limbHand; limbWound.location = 'hand'; limbWound.amount = 4; }
        if (healthInput.code == 4) limbPatient.ht = 9;
        if (healthInput.code == 6) limbWound.dropDestination = nil;
        if (healthInput.code >= 7 && healthInput.code <= 12)
        {
            limbPatient.bodyParts = [limbArm,limbHand,limbOtherArm,limbOtherHand];
            limbHeld.bodySupports = [limbHand,limbOtherHand]; limbHeld.modes = [limbTwoHandMode];
            limbPatient.dx = healthInput.code == 8 ? 10 : healthInput.code == 11 ? 2 : 11;
            if (healthInput.code == 9) limbPatient.ht = 9;
            if (healthInput.code == 12) { limbWound.amount = 12; limbWound.severing = true; }
        }
        if (healthInput.code == 13 || healthInput.code == 14)
        {
            healthRules.lastWounds = true; limbPatient.injury = 7; limbWound.amount = 1;
            limbWound.criticalHit = healthInput.code == 14;
        }
        if (healthInput.code == 15) limbWound.criticalHit = !limbWound.criticalHit;
        local result = limbWound.apply(); event('test.limb-wound'); eventValue(result.status); eventValue(result.reason);
        if (healthInput.code == 5 || healthInput.code == 10) throw new RpgError();
        return nil;
    }
;
limbAction: LimbFixtureAction;
limbVerb: Verb code = 1620 action = limbAction label = 'limb-fixture';
limbDuration: RpgExpandedCripplingDuration wound = limbWound combatEnded = true;
durationBattle: RpgLiteBattle;
class DurationFixtureAction: Action
    exec(context)
    {
        if (healthInput.code == 7) { rpgLiteHeal(limbPatient,1); return nil; }
        if (healthInput.code == 8)
        {
            local duplicate = new RpgExpandedCripplingDuration(); duplicate.wound = limbWound;
            duplicate.combatEnded = true; duplicate.apply(); return nil;
        }
        if (healthInput.code == 9) { limbDuration.combatEnded = nil; limbDuration.apply(); return nil; }
        if (healthInput.code == 4) { limbWound.amount = 12; limbWound.severing = true; limbDuration.combatEnded = nil; }
        if (limbWound.health == nil) limbWound.apply();
        limbPatient.ht = holds([1,5,6,10],healthInput.code) ? 11 : 10;
        if (healthInput.code == 3 || healthInput.code == 17) rpgRandom.seed(5);
        if (healthInput.code == 11)
        {
            local fighter = new RpgLiteFighter(); fighter.profile = limbPatient;
            durationBattle.fighters = [fighter]; durationBattle.active = true;
        }
        if (healthInput.code == 12) limbDuration.combatEnded = nil;
        if (healthInput.code == 13 || healthInput.code == 14)
        {
            local rapid = new RpgLiteTrait(); rapid.id = 'rapid-healing'; limbPatient.traits = [rapid];
            if (healthInput.code == 14)
            { local very = new RpgLiteTrait(); very.id = 'very-rapid-healing'; limbPatient.traits = [rapid,very]; }
        }
        if (healthInput.code == 15)
        { limbDuration.physician = healthPatient; limbDuration.medicalTL = 7; limbDuration.careEvidence = 'completed-clinic-care'; }
        local value = limbDuration.apply(); event('test.duration-outcome'); eventValue(value.status); eventValue(value.reason);
        if (holds([5,6,16,17],healthInput.code)) rpgLiteHeal(limbPatient,healthInput.code == 6 ? 5 : 6);
        if (healthInput.code == 10) throw new RpgError();
        return nil;
    }
;
durationAction: DurationFixtureAction;
durationVerb: Verb code = 1630 action = durationAction label = 'duration-fixture';
recoveryOne: RpgExpandedRecoveryMonth duration = limbDuration ordinal = 1 calendarId = 'harbor-calendar'
    boundaryId = 'injury-month-1' evidence = 'first calendar anniversary';
recoveryTwo: RpgExpandedRecoveryMonth duration = limbDuration ordinal = 2 calendarId = 'harbor-calendar'
    boundaryId = 'injury-month-2' evidence = 'second calendar anniversary';
recoveryThree: RpgExpandedRecoveryMonth duration = limbDuration ordinal = 3 calendarId = 'harbor-calendar'
    boundaryId = 'injury-month-3' evidence = 'third calendar anniversary';
class RecoveryFixtureAction: Action
    exec(context)
    {
        if (healthInput.code == 0)
        {
            limbWound.apply(); limbPatient.ht = 18; rpgRandom.seed(5); limbDuration.apply(); return nil;
        }
        local month = healthInput.code == 2 || healthInput.code == 8 ? recoveryTwo
            : healthInput.code == 3 || healthInput.code == 5 ? recoveryThree : recoveryOne;
        if (healthInput.code == 4)
        { event('test.recovery-preview'); eventValue(month.assess().reason); return nil; }
        if (healthInput.code == 6)
        {
            month = new RpgExpandedRecoveryMonth(); month.duration = limbDuration; month.ordinal = 2;
            month.calendarId = 'harbor-calendar'; month.boundaryId = recoveryOne.boundaryId; month.evidence = 'duplicate';
        }
        if (healthInput.code == 8) month.calendarId = 'different-calendar';
        if (healthInput.code == 10) month.boundaryId = 'different-boundary';
        if (healthInput.code == 12)
        {
            local wound = new RpgExpandedWound(); wound.id = 'later-injury'; wound.profile = limbPatient;
            wound.bodyPart = limbArm; wound.location = 'arm'; wound.amount = 6; wound.dropDestination = 'floor';
            wound.apply(); return nil;
        }
        month.reached = true; local value = month.apply(); event('test.recovery-month');
        eventValue(value.status); eventValue(value.reason);
        if (healthInput.code == 7) throw new RpgError();
        return nil;
    }
;
recoveryAction: RecoveryFixtureAction;
recoveryVerb: Verb code = 1640 action = recoveryAction label = 'recovery-fixture';
laterCareLow: RpgExpandedCripplingCare id = 'first-care' duration = limbDuration physician = healthPatient
    medicalTL = 5 evidence = 'completed low-technology care';
laterCareHigh: RpgExpandedCripplingCare id = 'improved-care' duration = limbDuration physician = healthPatient
    medicalTL = 7 evidence = 'completed improved care';
class LaterCareFixtureAction: Action
    exec(context)
    {
        if (healthInput.code == 8)
        {
            limbWound.apply(); limbPatient.ht = 18; rpgRandom.seed(5);
            limbDuration.physician = healthPatient; limbDuration.medicalTL = 5;
            limbDuration.careEvidence = 'initial completed care'; limbDuration.apply(); return nil;
        }
        local care = healthInput.code == 2 ? laterCareHigh : laterCareLow;
        if (healthInput.code == 3 || healthInput.code == 4)
        {
            care = new RpgExpandedCripplingCare(); care.id = healthInput.code == 4 ? 'first-care' : 'same-level-care';
            care.duration = limbDuration; care.physician = healthPatient; care.medicalTL = 5; care.evidence = 'later completed care';
        }
        if (healthInput.code == 5) care.medicalTL = 7;
        if (healthInput.code == 7) care.evidence = nil;
        local value = healthInput.code == 0 ? care.assess() : care.apply();
        event('test.later-care'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.monthsBefore); eventValue(value.monthsAfter); eventValue(value.recovered ? 1 : 0);
        if (healthInput.code == 6) throw new RpgError();
        return nil;
    }
;
laterCareAction: LaterCareFixtureAction;
laterCareVerb: Verb code = 1650 action = laterCareAction label = 'later-care-fixture';
naturalRules: RpgExpandedRules expandedNaturalRecovery = true;
naturalSlow: RpgLiteTrait id = 'slow-healing' level = 1;
naturalRapid: RpgLiteTrait id = 'rapid-healing' level = 2;
naturalPatient: RpgExpandedProfile rules = naturalRules st = 30 ht = 12 injury = 9 diseaseInjury = 2
    traits = [naturalSlow,naturalRapid];
class NaturalFixtureAction: Action
    exec(context)
    {
        local seconds = healthInput.code == 3 ? 86399 : healthInput.code == 4 ? 1 : 86400;
        local value = rpgLiteRest(naturalPatient,seconds,true,nil,nil,true);
        event('test.natural-session'); eventValue(value.healed);
        if (healthInput.code == 2) throw new RpgError();
        return nil;
    }
;
naturalAction: NaturalFixtureAction;
naturalVerb: Verb code = 1660 action = naturalAction label = 'natural-fixture';
medicalDoctor: RpgLiteProfile iq = 12 techLevel = 8;
medicalClinic: RpgExpandedMedicalPractice id = 'medical-clinic' physician = medicalDoctor advancedEquipment = true clean = true;
class MedicalFixtureAction: Action
    exec(context)
    {
        if (medicalClinic.skill == nil)
        {
            medicalClinic.skill = rpgLiteMakeSkill('physician',8,nil);
            local training = new RpgTraining(); training.skill = medicalClinic.skill; training.points = 4;
            medicalDoctor.skills = [training];
        }
        if (healthInput.code == 2) { medicalClinic.release(naturalPatient); return nil; }
        if (healthInput.code == 3)
        {
            local other = new RpgExpandedMedicalPractice(); other.id = 'duplicate-clinic'; other.physician = medicalDoctor;
            other.skill = medicalClinic.skill; other.advancedEquipment = true; other.assess(); return nil;
        }
        if (healthInput.code == 4)
        {
            local doctor = new RpgLiteProfile(); doctor.iq = 12; doctor.techLevel = 8;
            local training = new RpgTraining(); training.skill = medicalClinic.skill; training.points = 4; doctor.skills = [training];
            local other = new RpgExpandedMedicalPractice(); other.id = 'other-clinic'; other.physician = doctor;
            other.skill = medicalClinic.skill; other.advancedEquipment = true; other.admit(naturalPatient); return nil;
        }
        if (healthInput.code == 6) medicalClinic.available = nil;
        if (healthInput.code == 6 || healthInput.code == 7)
        {
            rpgLiteRest(naturalPatient,86400,true,nil,nil,true);
            local value = rpgLiteRest(naturalPatient,86400,true,nil,nil,true);
            event('test.supervised-rest'); eventValue(value.check.score); return nil;
        }
        local value = medicalClinic.admit(naturalPatient); event('test.medical-admission'); eventValue(value.status);
        if (healthInput.code == 5) throw new RpgError();
        return nil;
    }
;
medicalAction: MedicalFixtureAction;
medicalVerb: Verb code = 1670 action = medicalAction label = 'medical-fixture';
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
    if (verb == 1613)
    {
        event('test.wound-drop'); eventValue(healthHeld.usableBy(healthPatient) ? 1 : 0);
        eventValue(healthHeld.storageLocation); eventValue(healthHeld.ready ? 1 : 0);
        eventValue(healthWorn.ready ? 1 : 0); eventValue(healthWorn.worn ? 1 : 0);
        eventValue(healthPacked.storageLocation); eventValue(healthPatient.loadHundredths());
        eventValue(healthWound.droppedEquipment == nil ? 0 : healthWound.droppedEquipment.items.length());
        eventValue(healthFighter.aimSeconds); return nil;
    }
    if (verb == 1620) { healthInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1621)
    {
        event('test.limb-state'); eventValue(limbPatient.injury); eventValue(limbArm.disabled ? 1 : 0);
        eventValue(limbArm.severed ? 1 : 0); eventValue(limbHand.functional() ? 1 : 0);
        eventValue(limbHeld.storageLocation); eventValue(limbShield.storageLocation);
        eventValue(limbShield.worn ? 1 : 0); eventValue(limbShield.passiveDefenseBonus(limbPatient));
        eventValue(limbPatient.expandedWounds.length()); eventValue(rpgRandom.draws);
        eventValue(limbWound.health == nil ? 0 : limbWound.health.injury);
        eventValue(limbWound.bodyPart.disablingWound == limbWound ? 1 : 0); eventValue(rpgLedger.seconds);
        eventValue(limbWound.health != nil && limbWound.health.knockedDown ? 1 : 0); return nil;
    }
    if (verb == 1622)
    {
        local value = limbWound.assess(); event('test.limb-preview'); eventValue(value.status);
        eventValue(value.healthLoss); eventValue(value.crippling.crippled ? 1 : 0);
        eventValue(value.assessment.required ? 1 : 0); return nil;
    }
    if (verb == 1623)
    {
        local plan = limbWound.droppedLimbEquipment; event('test.limb-retention');
        eventValue(plan.checks.length()); eventValue(plan.checks.length() == 0 ? 0 : plan.checks[1].roll);
        eventValue(plan.checks.length() == 0 ? 0 : plan.checks[1].score);
        eventValue(plan.retainedItems.length()); eventValue(plan.items.length());
        eventValue(limbHeld.bodySupports.length()); eventValue(limbHeld.storageLocation); eventValue(rpgRandom.draws);
        local fighter = new RpgLiteFighter(); fighter.profile = limbPatient; fighter.weapon = limbHeld;
        eventValue(rpgLiteStrike(fighter,nil,new RpgLiteManeuver()).reason);
        eventValue(limbPatient.shock); eventValue(limbPatient.injury); return nil;
    }
    if (verb == 1630) { healthInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1631)
    {
        local value = limbDuration.result; event('test.duration-state');
        eventValue(limbPatient.injury); eventValue(limbArm.disabled ? 1 : 0);
        eventValue(value == nil ? nil : value.duration); eventValue(value == nil ? 0 : value.months);
        eventValue(value == nil ? 0 : value.monthRoll); eventValue(value == nil || value.check == nil ? 0 : value.check.score);
        eventValue(value == nil || value.check == nil ? 0 : value.check.roll); eventValue(rpgRandom.draws);
        eventValue(value != nil && value.recovered ? 1 : 0); eventValue(limbWound.durationRecord == limbDuration ? 1 : 0);
        eventValue(limbArm.disablingWound != nil ? 1 : 0); return nil;
    }
    if (verb == 1640) { healthInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1641)
    {
        event('test.recovery-state'); eventValue(limbDuration.recoveryMonths.length());
        eventValue(limbArm.disabled ? 1 : 0); eventValue(limbDuration.result.recovered ? 1 : 0);
        eventValue(limbPatient.injury); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        eventValue(limbArm.disablingWound != nil ? 1 : 0); eventValue(limbDuration.result.months); return nil;
    }
    if (verb == 1624)
    {
        event('test.last-wound-state'); eventValue(limbWound.ignored ? 1 : 0);
        eventValue(limbWound.assess().ignored ? 1 : 0); eventValue(limbPatient.injury);
        eventValue(limbPatient.woundSerial); eventValue(rpgRandom.draws); eventValue(limbPatient.expandedWounds.length()); return nil;
    }
    if (verb == 1650) { healthInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1651)
    {
        event('test.later-care-state'); eventValue(limbDuration.requiredMonths()); eventValue(limbDuration.laterCare.length());
        eventValue(limbDuration.result.months); eventValue(limbDuration.result.monthRoll); eventValue(limbPatient.injury);
        eventValue(limbArm.disabled ? 1 : 0); eventValue(limbDuration.result.recovered ? 1 : 0);
        eventValue(limbDuration.recoveryMonths.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 1660) { healthInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1661)
    {
        event('test.natural-state'); eventValue(naturalPatient.injury); eventValue(naturalPatient.healingClock);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 1670) { healthInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1671)
    {
        event('test.medical-roster'); eventValue(medicalClinic.patients.length());
        eventValue(medicalDoctor.medicalPractice == medicalClinic ? 1 : 0);
        eventValue(naturalPatient.medicalSupervision == medicalClinic ? 1 : 0);
        eventValue(naturalPatient.naturalRecoveryModifier()); eventValue(naturalPatient.injury);
        eventValue(naturalPatient.healingClock); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return vhylAct(verb,args);
}
