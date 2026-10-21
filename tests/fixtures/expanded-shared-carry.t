#include "expanded-equipment-lift.t"
carryPartner: RpgExpandedProfile rules = bleedRules;
sharedCarry: RpgExpandedSharedCarry id = 'crate-team' owner = bleedProfile item = liftCrate sourceLocation = bleedRoom
    members = [[bleedProfile,2000,2,[]],[carryPartner,4000,2,[]]] approved = true
    evidence = 'Two participants have suitable access; the authored grips assign unequal load shares';
carryStorage: RpgExpandedEquipmentStorage profile = bleedProfile item = liftCrate accessible = true;
carryTrade: RpgExpandedTradeTransfer id = 'crate-sale' seller = bleedProfile buyer = carryPartner item = liftCrate
    buyerAgrees = true sellerAgrees = true available = true permitted = true;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 780) { sharedCarry.assess(); return nil; }
        if (code == 781 || code == 782)
        { sharedCarry.lift(); if (code == 782) throw new RpgError(); return nil; }
        if (code == 783)
        {
            event('test.shared-carry'); eventValue(bleedProfile.loadHundredths()); eventValue(carryPartner.loadHundredths());
            eventValue(bleedProfile.equipment.length()); eventValue(carryPartner.equipment.length());
            eventValue(bleedProfile.sharedCarries.length()); eventValue(carryPartner.sharedCarries.length());
            eventValue(liftCrate.sharedCarry != nil ? 1 : 0); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 784 || code == 785)
        { sharedCarry.lower(bleedRoom,2,'The group sets the crate down in an authored two-second action');
          if (code == 785) throw new RpgError(); return nil; }
        if (code == 786)
        {
            event('test.shared-carry-guards'); eventValue(carryStorage.assess().reason);
            eventValue(carryTrade.assess().reason); eventValue(liftOperation.assess().reason); return nil;
        }
        if (code == 787) { sharedCarry.members = [[bleedProfile,2000,2,[]],[carryPartner,3999,2,[]]]; return nil; }
        if (code == 788) { carryPartner.unconscious = true; return nil; }
        return inherited(context);
    }
;
