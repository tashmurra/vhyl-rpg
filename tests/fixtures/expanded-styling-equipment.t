#include "expanded-styling.t"
stylingCoat: RpgLiteItem id = 'styled-coat' weight = 300;
stylingScarf: RpgLiteItem id = 'styled-scarf' weight = 20;
stylingInventoryOutfit: RpgExpandedInventoryOutfit id = 'coat-and-scarf' owner = crossPhysician items = [stylingCoat,stylingScarf];
modify crossPhysician equipment = [stylingCoat,stylingScarf];
modify stylingPrepFixture outfit = stylingInventoryOutfit;
modify appearanceReaction stylingOutfit = stylingInventoryOutfit stylingWorn = nil;
stylingCoatTransfer: RpgExpandedTradeTransfer id = 'give-coat-back' seller = crossPhysician buyer = stylingDesigner
    item = stylingCoat buyerAgrees = true sellerAgrees = true available = true permitted = true;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 25100) { stylingCoat.worn = true; stylingScarf.worn = true; return nil; }
        if (code == 25101) { stylingScarf.worn = nil; return nil; }
        if (code == 25102) { stylingScarf.storageLocation = healthRoom; return nil; }
        if (code == 25103) { stylingScarf.storageLocation = nil; return nil; }
        if (code == 25104) { stylingCoatTransfer.transfer(); return nil; }
        if (code == 25105)
        {
            stylingInventoryOutfit.items = [stylingCoat];
            try { stylingPrepFixture.assess(); }
            catch (RpgExpandedError error) { event('test.styling-equipment-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
