#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-combat.t>
dropRoom: Room 'Training Yard';
dropRules: RpgExpandedRules;
dropPatient: RpgExpandedProfile rules = dropRules equipment = [dropFirst,dropSecond,dropLamp,dropWorn,dropPacked];
dropFirst: RpgLiteWeapon id = 'first' ready = true weight = 100;
dropSecond: RpgLiteWeapon id = 'second' ready = true weight = 100;
dropLamp: RpgLiteItem id = 'lamp' ready = true weight = 100;
dropWorn: RpgLiteItem id = 'worn' ready = true worn = true weight = 100 db = 1;
dropPacked: RpgLiteItem id = 'packed' weight = 100;
dropFighter: RpgLiteFighter profile = dropPatient shield = dropWorn aimWeapon = dropFirst aimSeconds = 2;
dropRequest: RpgExpandedCriticalDrop id = 'critical-drop' profile = dropPatient
    evidence = 'Recorded qualifying critical-hit table result' destination = 'yard';
readinessRequest: RpgExpandedCriticalReadiness id = 'weapon-readiness' profile = dropPatient
    weapon = dropFirst evidence = 'Recorded weapon critical miss';
defenseRequest: RpgExpandedDefenseFailure id = 'critical-defense' fighter = dropFighter
    evidence = 'Recorded eligible defense roll';
defenseIncoming: RpgLiteAttackMode;
defenseWeapon: RpgLiteWeapon modes = [defenseIncoming];
defenseAttacker: RpgLiteFighter weapon = defenseWeapon;
defenseContext: RpgLiteManeuver;
dropInput: object code = 0;
class CriticalDropAction: Action
    exec(context)
    {
        local code = dropInput.code;
        if (code >= 30)
        {
            if (code == 32 || code == 33) defenseRequest.kind = 'block';
            if (code == 34) { dropWorn.ready = true; dropPatient.posture = 'standing'; return nil; }
            if (code == 35) defenseRequest.evidence = 'Changed evidence';
            if (code == 36) defenseRequest.mobility = 'flying';
            if (code == 37) { defenseRequest.score = 16; defenseRequest.roll = 17; }
            if (code == 38) dropPatient.posture = 'lying';
            local defense = code == 39 ? defenseRequest.assess() : defenseRequest.apply();
            event('test.critical-defense-operation'); eventValue(defense.status); eventValue(defense.reason);
            if (code == 31 || code == 33) throw new RpgError(); return nil;
        }
        if (code >= 20)
        {
            if (code == 24) { dropFirst.ready = true; return nil; }
            if (code == 25) readinessRequest.evidence = 'Changed evidence';
            if (code == 26) readinessRequest.tableRoll = 12;
            local readiness = code == 23 ? readinessRequest.assess() : readinessRequest.apply();
            event('test.critical-readiness-operation'); eventValue(readiness.status); eventValue(readiness.reason);
            if (code == 21) throw new RpgError(); return nil;
        }
        if (code == 2 || code == 3 || code == 11) dropRequest.trigger = 'head-14';
        if (code == 4) dropRequest.destination = nil;
        if (code == 5) dropRequest.evidence = 'Changed trigger';
        if (code == 8) { dropPatient.validateFeatures(); return nil; }
        if (code == 7)
        {
            local pickup = new RpgExpandedEquipmentStorage(); pickup.profile = dropPatient;
            pickup.item = dropRequest.result.items[1]; pickup.accessible = true; pickup.move();
            pickup.item.ready = true; return nil;
        }
        if (code == 9)
        {
            local preview = dropRequest.assess(); event('test.critical-drop-operation');
            eventValue(preview.status); eventValue(preview.reason); return nil;
        }
        if (dropRequest.result == nil) rpgRandom.seed(code == 11 ? 3 : 1);
        local value = dropRequest.apply(); event('test.critical-drop-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 1 || code == 3) throw new RpgError(); return nil;
    }
;
criticalDropAction: CriticalDropAction;
criticalDropVerb: Verb code = 2030 action = criticalDropAction label = 'critical-drop';
modify gameMain initialRoom = dropRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2030) { dropInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2033)
    {
        event('test.critical-defense-state'); eventValue(dropPatient.posture); eventValue(dropWorn.ready ? 1 : 0);
        eventValue(dropPatient.criticalDefenseFailures.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        eventValue(rpgLiteDefenseScore(dropFighter,defenseAttacker,defenseContext,'dodge')); return nil;
    }
    if (verb == 2032)
    {
        event('test.critical-readiness-state'); eventValue(dropFirst.ready ? 1 : 0);
        eventValue(dropFighter.aimSeconds); eventValue(dropPatient.criticalReadiness.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2031)
    {
        event('test.critical-drop-state'); eventValue(dropFirst.storageLocation); eventValue(dropSecond.storageLocation);
        eventValue(dropLamp.storageLocation); eventValue(dropWorn.ready ? 1 : 0); eventValue(dropPacked.storageLocation);
        eventValue(dropPatient.loadHundredths()); eventValue(dropPatient.criticalDrops.length());
        eventValue(dropRequest.result == nil ? 0 : dropRequest.result.items.length());
        eventValue(dropFighter.aimSeconds); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return vhylAct(verb,args);
}
