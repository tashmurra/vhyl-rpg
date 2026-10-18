#include "expanded-packing-transfer.t"
modify packingCargo weight = 11000;
modify packingAnimal equipment = [packingCargo];
modify crossPhysician equipment = [];
packOverload: RpgExpandedOverloadCarry id = 'back-load' profile = packingAnimal approved = true evidence = 'Supported back load suited to this animal';
packLiteOverload: RpgLiteJourney profile = packingAnimal kind = 'overload';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 23100) { packOverload.start(); return nil; }
        if (code == 23101 || code == 23102) { rpgSpendTime(1); if (code == 23102) throw new RpgError(); return nil; }
        if (code == 23103)
        { event('test.overload-state'); eventValue(packingAnimal.fatigue); eventValue(packOverload.chargedSeconds);
          eventValue(rpgLedger.seconds); eventValue(packingAnimal.overloadCarry == packOverload); eventValue(rpgRandom.draws); return nil; }
        if (code == 23104) { packingCargo.weight = 10000; return nil; }
        if (code == 23105 || code == 23106)
        {
            try { if (code == 23105) rpgSpendTime(2); else packLiteOverload.advance(1); }
            catch (RpgExpandedError error) { event('test.overload-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 23107) { packOverload.charge(rpgLedger.seconds - 1); return nil; }
        return inherited(context);
    }
;
