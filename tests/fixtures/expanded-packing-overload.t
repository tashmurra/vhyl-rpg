#include "expanded-packing-bundle.t"
packingLoadSupport: RpgExpandedOverloadCarry id = 'packed-back-load' profile = packingAnimal approved = true evidence = 'Harness and body form support this back load';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 23200) { packingBundle.overload = packingLoadSupport; return nil; }
        if (code == 23201) { rpgSpendTime(1); return nil; }
        if (code == 23202)
        { event('test.packed-overload'); eventValue(packingAnimal.fatigue); eventValue(packingAnimal.overloadCarries.length());
          eventValue(packingAnimal.overloadCarry == packingLoadSupport); eventValue(rpgLedger.seconds); return nil; }
        if (code == 23203) { packingSecondCargo.weight = 20000; return nil; }
        if (code == 23204) { packingLoadSupport.approved = nil; return nil; }
        if (code == 23205) { packingTransfer.overload = packingLoadSupport; packingCargo.weight = 11000; return nil; }
        return inherited(context);
    }
;
