#include "expanded-packing-transfer.t"
packingSecondCargo: RpgLiteItem id = 'second-cargo' weight = 200 quantity = 1;
modify crossPhysician
    equipment = [packingCargo,packingSecondCargo]
    breakBundle = nil
    onEquipmentUnavailable(item,reason)
    {
        inherited(item,reason);
        if (self.breakBundle && item == packingCargo) packingEntryTwo.permitted = nil;
    }
;
packingBundle: RpgExpandedPackingBundle id = 'load-bundle' attempt = packingAttempt transfers = [packingEntryOne,packingEntryTwo]
    approved = true evidence = 'Both stacks form the approved restrained load';
packingEntryOne: RpgExpandedPackingBundleEntry id = 'bundle-one' bundle = packingBundle seller = crossPhysician buyer = packingAnimal
    item = packingCargo buyerAgrees = true sellerAgrees = true available = true permitted = true;
packingEntryTwo: RpgExpandedPackingBundleEntry id = 'bundle-two' bundle = packingBundle seller = crossPhysician buyer = packingAnimal
    item = packingSecondCargo buyerAgrees = true sellerAgrees = true available = true permitted = true;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 23000 || code == 23001 || code == 23002)
        { local value = code == 23002 ? packingBundle.assess() : packingEntryOne.transfer();
          event('test.packing-bundle'); eventValue(value.status); eventValue(value.reason);
          if (code == 23001) throw new RpgError(); return nil; }
        if (code == 23003)
        { event('test.bundle-inventory'); eventValue(crossPhysician.equipment.length()); eventValue(packingAnimal.equipment.length());
          eventValue(packingAnimal.tradeReceipts.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 23004) { packingSecondCargo.storageLocation = healthRoom; return nil; }
        if (code == 23005) { packingCargo.weight = 6000; packingSecondCargo.weight = 12000; return nil; }
        if (code == 23006)
        {
            packingBundle.evidence = 'Changed bundle';
            try { packingBundle.transfer(); }
            catch (RpgExpandedError error) { event('test.bundle-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 23007) { crossPhysician.breakBundle = true; return nil; }
        return inherited(context);
    }
;
