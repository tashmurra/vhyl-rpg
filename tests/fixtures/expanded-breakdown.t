#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-technology.t>
breakdownRoom: Room 'Workshop';
breakdownItem: RpgLiteItem requiresMaintenance = true;
breakdownRequest: RpgExpandedBreakdown id = 'dust' item = breakdownItem evidence = 'Careless exposure to dust';
repairProfile: RpgLiteProfile skills = [repairTraining];
repairSkill: RpgLiteSkill id = 'mechanic' attribute = rpgIQ difficulty = 0;
repairTraining: RpgTraining skill = repairSkill points = 1;
repairRequest: RpgExpandedBreakdownRepair id = 'repair-first' failure = breakdownRequest repairer = repairProfile
    skill = repairSkill approvedSkill = true uninterrupted = true evidence = 'Suitable mechanic and tools for the fault';
repairRetry: RpgExpandedBreakdownRepair id = 'repair-retry' failure = breakdownRequest repairer = repairProfile
    skill = repairSkill approvedSkill = true uninterrupted = true evidence = 'Second uninterrupted attempt';
partsRules: RpgExpandedRules;
partsPayer: RpgExpandedProfile rules = partsRules money = 1000;
partsRequest: RpgExpandedRepairParts failure = breakdownRequest payer = partsPayer weight = 50
    evidence = 'Available suitable replacement parts' available = true permitted = true;
breakdownInput: object code = 0;
class BreakdownAction: Action
    exec(context)
    {
        local code = breakdownInput.code;
        if (code >= 30)
        {
            if (code == 30)
            {
                breakdownItem.cost = 500; rpgRandom.seed(5); breakdownRequest.apply(); rpgRandom.seed(1); return nil;
            }
            if (code == 34) partsPayer.money = 99;
            if (code == 35) partsPayer.money = 1000;
            if (code == 36) { repairProfile.iq = 12; rpgRandom.seed(1); repairRetry.apply(); return nil; }
            if (code == 37) { partsRequest.evidence = 'Changed supply'; partsRequest.quote(); return nil; }
            if (code == 39)
            {
                local another = new RpgExpandedRepairParts(); another.failure = breakdownRequest; another.payer = partsPayer;
                another.evidence = 'Another supplier'; another.available = true; another.permitted = true;
                local attempt = another.quote(); event('test.parts-operation'); eventValue(attempt.status); eventValue(attempt.reason); return nil;
            }
            if (code == 40 || code == 41)
            {
                if (code == 40) partsRequest.package.storageLocation = 'shelf';
                else partsPayer.equipment = partsPayer.equipment + [partsRequest.package];
                local preview = repairRequest.assess(); event('test.repair-operation');
                eventValue(preview.status); eventValue(preview.reason); eventValue(preview.repaired ? 1 : 0); return nil;
            }
            local parts = code == 31 || code == 32 ? partsRequest.quote() : partsRequest.purchase();
            event('test.parts-operation'); eventValue(parts.status); eventValue(parts.reason);
            if (code == 32 || code == 38) throw new RpgError(); return nil;
        }
        if (code >= 20)
        {
            if (code == 20)
            {
                breakdownItem.artifactHT = 12; breakdownItem.cost = 500; rpgRandom.seed(5);
                breakdownRequest.apply(); rpgRandom.seed(1); return nil;
            }
            if (code == 24) repairRequest.approvedSkill = nil;
            if (code == 25) rpgRandom.seed(5);
            if (code == 26) rpgRandom.seed(1);
            if (code == 27) repairRequest.evidence = 'Changed repair';
            local repair = code == 23 ? repairRequest.assess() : code == 26 ? repairRetry.apply() : repairRequest.apply();
            event('test.repair-operation'); eventValue(repair.status); eventValue(repair.reason); eventValue(repair.repaired ? 1 : 0);
            if (code == 22) throw new RpgError(); return nil;
        }
        if (code == 2) { breakdownItem.artifactHT = 12; rpgRandom.seed(5); }
        if (code == 3) rpgRandom.seed(5);
        if (code == 4) breakdownRequest.trigger = 'extreme-day';
        if (code == 5 || code == 11 || code == 12)
        {
            local another = new RpgExpandedBreakdown(); another.id = 'second-day-check'; another.item = breakdownItem;
            another.trigger = code == 12 ? 'careless-exposure' : 'extreme-day'; another.evidence = 'Recorded additional exposure';
            if (code == 11) rpgSpendTime(86400);
            local duplicate = another.apply(); event('test.breakdown-operation'); eventValue(duplicate.status); eventValue(duplicate.reason); return nil;
        }
        if (code == 6) breakdownRequest.evidence = 'Changed evidence';
        if (code == 8) { breakdownItem.maintenanceHTLoss = 3; breakdownRequest.brutality = -2; }
        if (code == 9) { breakdownItem.storageLocation = 'shelf'; return nil; }
        if (code == 13) { breakdownItem.artifactHT = 1; breakdownItem.maintenanceHTLoss = 3; }
        if (code == 10) { breakdownItem.requiresMaintenance = nil; }
        local value = code == 7 ? breakdownRequest.assess() : breakdownRequest.apply();
        event('test.breakdown-operation'); eventValue(value.status); eventValue(value.reason);
        if (code == 1) throw new RpgError(); return nil;
    }
;
breakdownAction: BreakdownAction;
breakdownVerb: Verb code = 2060 action = breakdownAction label = 'exposure';
modify gameMain initialRoom = breakdownRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2060) { breakdownInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2064)
    {
        event('test.parts-state'); eventValue(partsPayer.money); eventValue(partsPayer.equipment.length());
        eventValue(partsPayer.loadHundredths()); eventValue(partsRequest.result == nil ? nil : partsRequest.result.price);
        eventValue(partsRequest.installed ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2062)
    {
        event('test.repair-state'); eventValue(breakdownItem.usableBy(nil) ? 1 : 0);
        eventValue(breakdownRequest.repairs.length()); eventValue(breakdownRequest.repairedBy == nil ? 0 : 1);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2063)
    {
        event('test.repair-prices'); eventValue(rpgExpandedRepairPriceModifier(args[1]));
        eventValue(rpgExpandedRepairPartsPrice(args[1],args[2])); return nil;
    }
    if (verb == 2061)
    {
        event('test.breakdown-state'); eventValue(breakdownItem.usableBy(nil) ? 1 : 0);
        eventValue(breakdownItem.environmentFailures.length()); eventValue(breakdownItem.environmentFailure == nil ? nil : breakdownItem.environmentFailure.result.repair);
        eventValue(breakdownRequest.result == nil ? nil : breakdownRequest.result.check.score);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return vhylAct(verb,args);
}
