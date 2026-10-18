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
        local result = limbWound.apply(); event('test.limb-wound'); eventValue(result.status); eventValue(result.reason);
        if (healthInput.code == 5 || healthInput.code == 10) throw new RpgError();
        return nil;
    }
;
limbAction: LimbFixtureAction;
limbVerb: Verb code = 1620 action = limbAction label = 'limb-fixture';
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
    return vhylAct(verb,args);
}
