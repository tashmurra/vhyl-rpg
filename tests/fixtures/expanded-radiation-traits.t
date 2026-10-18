#include "expanded-radiation.t"
#include <vhyl-rpg-expanded-traits.t>
#include <vhyl-rpg-expanded-characters.t>
radiationTrait: RpgExpandedRadiationResistance approved = true level = 1;
modify radiationProfile traits = [radiationTrait];
modify RadiationTestAction
    exec(context)
    {
        local code = radiationInput.code;
        if (code == 20) { radiationTrait.level = radiationInput.days; return nil; }
        if (code == 21) { radiationTrait.active = nil; return nil; }
        if (code == 22) { radiationTrait.mitigated = true; return nil; }
        if (code == 23) { radiationTrait.percentages = [-10]; return nil; }
        if (code == 24)
        {
            event('test.radiation-trait'); eventValue(radiationTrait.creationCost());
            eventValue(radiationProfile.radiationDivisor());
            eventValue(rpgExpandedCharacterCost(radiationProfile,nil)); return nil;
        }
        return inherited(context);
    }
;
