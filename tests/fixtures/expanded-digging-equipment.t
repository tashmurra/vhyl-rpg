#include "expanded-digging-work.t"
#include <vhyl-rpg-expanded-equipment.t>
modify bleedProfile equipment = [] money = 30;
digToolInput: object pick = nil shovel = nil;
digToolPurchase: RpgExpandedAcquisition profile = bleedProfile available = true permitted = true;
digShovelPurchase: RpgExpandedAcquisition profile = bleedProfile available = true permitted = true;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 650)
        {
            digToolInput.pick = rpgExpandedDiggingTool('catalogue-pick','pickaxe');
            digToolInput.shovel = rpgExpandedDiggingTool('catalogue-shovel','shovel');
            digToolPurchase.item = digToolInput.pick; digShovelPurchase.item = digToolInput.shovel;
            digHour.pick = digToolInput.pick; digHour.shovel = digToolInput.shovel; return nil;
        }
        if (code == 651 || code == 652)
        { digToolPurchase.acquire(); digShovelPurchase.acquire(); if (code == 652) throw new RpgError(); return nil; }
        if (code == 653)
        {
            event('test.digging-tools'); eventValue(bleedProfile.money); eventValue(bleedProfile.equipment.length());
            eventValue(bleedProfile.loadHundredths()); eventValue(digToolInput.pick.techLevel); eventValue(digToolInput.shovel.techLevel);
            eventValue(digSite.hours.length()); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 654)
        {
            digToolInput.pick.diggingMaterial = 'metal'; digToolInput.shovel.diggingMaterial = 'metal';
            digToolInput.pick.materialEvidence = 'The inspected tool uses iron';
            digToolInput.shovel.materialEvidence = 'The inspected blade uses iron'; return nil;
        }
        if (code == 655) { digHour.shovel = digToolInput.pick; return nil; }
        if (code == 656) { digToolInput.shovel.storageLocation = bleedRoom; return nil; }
        if (code == 657) { digToolInput.pick.cost = 1; return nil; }
        return inherited(context);
    }
;
