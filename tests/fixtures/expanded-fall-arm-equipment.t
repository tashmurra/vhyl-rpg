#include "expanded-fall-arm.t"
#include <vhyl-rpg-expanded-equipment.t>
fallLeftTool: RpgLiteWeapon id = 'left-tool' ready = true bodySupports = [fallHand];
fallSharedTool: RpgLiteWeapon id = 'shared-tool' ready = true bodySupports = [fallHand,fallOtherHand];
modify bleedProfile equipment = [fallLeftTool,fallSharedTool];
modify fallInjury dropDestination = bleedRoom;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 940)
        {
            event('test.fall-arm-equipment'); eventValue(bleedProfile.injury);
            eventValue(fallLeftTool.storageLocation == bleedRoom ? 1 : 0);
            eventValue(fallSharedTool.storageLocation == bleedRoom ? 1 : 0);
            eventValue(fallSharedTool.bodySupports.length()); eventValue(fallSharedTool.ready ? 1 : 0);
            eventValue(bleedProfile.equipment.length()); eventValue(rpgRandom.draws);
            eventValue(bleedProfile.expandedWounds.length()); return nil;
        }
        if (code == 941) { fallInjury.dropDestination = nil; return nil; }
        if (code == 942) { bleedInput.forcedRoll = 17; return nil; }
        return inherited(context);
    }
;
