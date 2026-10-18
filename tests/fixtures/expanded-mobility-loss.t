#include "expanded-mobility-settlement.t"
crutchHandWound: RpgExpandedWound id = 'support-hand-hit' profile = bleedProfile
    bodyPart = crutchLeftHand location = 'hand' amount = 4 dropDestination = bleedRoom;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1000 || code == 1001)
        {
            local plan = bleedProfile.prepareForcedDrop([crutchItem],bleedRoom); plan.commit();
            if (code == 1001) throw new RpgError(); return nil;
        }
        if (code == 1002) { crutchItem.storageLocation = nil; crutchItem.ready = true; return nil; }
        if (code == 1003)
        {
            event('test.mobility-loss'); eventValue(crutchSupport.lossEvents.length());
            eventValue(crutchSupport.pendingLoss() ? 1 : 0); eventValue(bleedProfile.mobilitySupport == nil ? 0 : 1);
            eventValue(crutchItem.storageLocation == bleedRoom ? 1 : 0);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1004) { bleedProfile.onEquipmentDropped(crutchItem); return nil; }
        if (code == 1005) { crutchHandWound.apply(); return nil; }
        return inherited(context);
    }
;
