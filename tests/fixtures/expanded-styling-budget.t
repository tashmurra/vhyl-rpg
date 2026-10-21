#include "expanded-styling-equipment.t"
#include <vhyl-rpg-expanded-campaign.t>
stylingClothingPrice: RpgExpandedLifestyle status = 4 kind = 'ordinary-outfit' conservativeOutfit = true;
stylingClothingPackage: RpgExpandedLifestyleItem id = 'reception-clothing' lifestyle = stylingClothingPrice
    approved = true evidence = 'An ordinary outfit under the conservative clothing convention';
modify stylingInventoryOutfit items = [stylingClothingPackage];
modify crossPhysician equipment = [stylingClothingPackage];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 25200)
        { local value = stylingClothingPrice.assess(); event('test.styling-budget'); eventValue(value.money);
          eventValue(stylingClothingPackage.stylingUseReason(crossPhysician)); return nil; }
        if (code == 25201) { stylingClothingPrice.fashionBenefit = true; return nil; }
        if (code == 25202) { stylingClothingPackage.worn = true; return nil; }
        if (code == 25203) { stylingClothingPrice.status = 2; return nil; }
        if (code == 25204) { stylingClothingPrice.kind = 'wardrobe'; stylingClothingPrice.conservativeOutfit = nil;
            stylingClothingPackage.exactWeight = 2000; return nil; }
        if (code == 25205) { stylingClothingPrice.conservativeOutfit = nil; return nil; }
        return inherited(context);
    }
;
