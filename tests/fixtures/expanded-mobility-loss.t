#include "expanded-mobility-settlement.t"
crutchHandWound: RpgExpandedWound id = 'support-hand-hit' profile = bleedProfile
    bodyPart = crutchLeftHand location = 'hand' amount = 4 dropDestination = bleedRoom;
mobilityStorage: RpgExpandedEquipmentStorage profile = bleedProfile item = crutchItem
    destination = bleedRoom accessible = true;
mobilityBuyer: RpgExpandedProfile rules = bleedRules;
mobilityTrade: RpgExpandedTradeTransfer id = 'aid-sale' seller = bleedProfile buyer = mobilityBuyer
    item = crutchItem price = 0 buyerAgrees = true sellerAgrees = true available = true permitted = true;
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
        if (code == 1006 || code == 1007)
        {
            mobilityStorage.move(); if (code == 1007) throw new RpgError(); return nil;
        }
        if (code == 1008 || code == 1009)
        {
            mobilityTrade.transfer(); if (code == 1009) throw new RpgError(); return nil;
        }
        return inherited(context);
    }
;
