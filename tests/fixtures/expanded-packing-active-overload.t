#include "expanded-packing-overload.t"
packingExtraCargo: RpgLiteItem id = 'extra-cargo' weight = 1000;
packingExtraOccurrence: object;
packingExtraAttempt: RpgExpandedPackingAttempt id = 'extra-load' profile = crossPhysician animal = packingAnimal
    skill = packingCatalogue occurrence = packingExtraOccurrence approved = true evidence = 'Additional stack fits the existing harness';
packingExtraTransfer: RpgExpandedPackingTransfer id = 'extra-transfer' attempt = packingExtraAttempt
    seller = crossPhysician buyer = packingAnimal item = packingExtraCargo overload = packingLoadSupport
    buyerAgrees = true sellerAgrees = true available = true permitted = true evidence = 'Combined load remains supported';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 23300) { crossPhysician.equipment = crossPhysician.equipment + [packingExtraCargo]; packingExtraAttempt.resolve(); return nil; }
        if (code == 23301 || code == 23302 || code == 23303)
        { local value = code == 23303 ? packingExtraTransfer.assess() : packingExtraTransfer.transfer();
          event('test.active-load'); eventValue(value.status); eventValue(value.reason);
          if (code == 23302) throw new RpgError(); return nil; }
        if (code == 23304)
        { event('test.active-load-state'); eventValue(holds(packingAnimal.equipment,packingExtraCargo)); eventValue(packingLoadSupport.startedAt);
          eventValue(packingLoadSupport.chargedSeconds); eventValue(packingAnimal.overloadCarries.length()); eventValue(rpgLedger.seconds); return nil; }
        if (code == 23305) { packingExtraCargo.weight = 10000; return nil; }
        return inherited(context);
    }
;
