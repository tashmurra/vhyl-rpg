#include "expanded-makeup-equipment.t"
makeupPigment: RpgLiteItem id = 'stage-pigment' quantity = 2;
makeupMaterialDebit: RpgExpandedInventoryMakeupMaterials application = makeupApplicationFixture
    stock = makeupPigment units = 2 approved = true evidence = 'This design uses two measured pigment portions';
modify makeupApplicationFixture materials = makeupMaterialDebit materialsAvailable = nil;
modify crossPhysician equipment = [makeupKit,makeupPigment];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 26000)
        { event('test.makeup-materials'); eventValue(makeupPigment.quantity);
          eventValue(holds(crossPhysician.equipment,makeupPigment) ? 1 : 0);
          eventValue(makeupMaterialDebit.consumed ? 1 : 0); return nil; }
        if (code == 26001) { makeupPigment.quantity = 1; return nil; }
        if (code == 26002) { makeupPigment.storageLocation = healthRoom; return nil; }
        if (code == 26003) { crossPhysician.fatigue = crossPhysician.maxEnergy; rpgRandom.medicalRoll = 13; return nil; }
        return inherited(context);
    }
;
