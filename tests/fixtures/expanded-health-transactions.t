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
    return vhylAct(verb,args);
}
