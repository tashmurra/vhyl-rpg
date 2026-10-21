#include "expanded-packing-attempt.t"
packingCargo: RpgLiteItem id = 'cargo' weight = 100 quantity = 2;
modify crossPhysician equipment = [packingCargo];
modify packingAttempt difficult = nil;
packingTransfer: RpgExpandedPackingTransfer id = 'cargo-load' attempt = packingAttempt seller = crossPhysician buyer = packingAnimal
    item = packingCargo buyerAgrees = true sellerAgrees = true available = true permitted = true evidence = 'Load placement and restraint are suitable';
packingUnload: RpgExpandedPackingAttempt id = 'unload-animal' profile = crossPhysician animal = packingAnimal
    skill = packingCatalogue occurrence = packingOccurrence task = 'unload' approved = true evidence = 'Unload the same stack';
packingUnloadTransfer: RpgExpandedPackingTransfer id = 'cargo-unload' attempt = packingUnload seller = packingAnimal buyer = crossPhysician
    item = packingCargo buyerAgrees = true sellerAgrees = true available = true permitted = true evidence = 'Safe unloading position';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 22900 || code == 22901)
        { local value = packingTransfer.transfer(); event('test.packing-transfer'); eventValue(value.status); eventValue(value.reason);
          if (code == 22901) throw new RpgError(); return nil; }
        if (code == 22902)
        { event('test.packing-inventory'); eventValue(holds(crossPhysician.equipment,packingCargo)); eventValue(holds(packingAnimal.equipment,packingCargo));
          eventValue(packingAnimal.tradeReceipts.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 22903) { packingCargo.weight = 100000; return nil; }
        if (code == 22904) { packingCargo.storageLocation = healthRoom; return nil; }
        if (code == 22905)
        { local value = packingTransfer.assess(); event('test.packing-transfer'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 22906)
        {
            packingTransfer.evidence = 'Changed load facts';
            try { packingTransfer.transfer(); }
            catch (RpgExpandedError error) { event('test.packing-transfer-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 22907) { packingUnload.resolve(); packingUnloadTransfer.transfer(); return nil; }
        return inherited(context);
    }
;
