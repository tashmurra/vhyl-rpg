#include "expanded-fishing-forage.t"
ownedFishingKit: RpgLiteItem id = 'river-kit' quantity = 1;
otherFishingKit: RpgLiteItem id = 'other-river-kit' quantity = 1;
fishingStore: object;
ownedFishingEquipment: RpgExpandedOwnedEquipmentAssessment
    profile = bleedProfile skill = fishingSkill items = [ownedFishingKit]
    approved = true evidence = 'Owned hook and line suitable for this river';
modify fishingTools equipmentAssessment = ownedFishingEquipment;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 15400) { bleedProfile.equipment = [ownedFishingKit,otherFishingKit]; return nil; }
        if (code == 15401)
        {
            bleedProfile.equipment = []; bleedHealer.equipment = [ownedFishingKit];
            ownedFishingEquipment.profile = bleedHealer; return nil;
        }
        if (code == 15402) { ownedFishingKit.storageLocation = fishingStore; return nil; }
        if (code == 15403) { ownedFishingEquipment.items = [otherFishingKit]; return nil; }
        if (code == 15404)
        {
            event('test.owned-fishing-preview');
            try { local value = fishingAttempt.assess(); eventValue(value.status); eventValue(value.reason); }
            catch (RpgExpandedError error) { eventValue('rejected'); eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
