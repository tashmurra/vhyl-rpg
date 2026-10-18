#include "expanded-market-offers.t"
ownedToolSkill: RpgLiteSkill id = 'craft' attribute = rpgIQ difficulty = 0;
ownedToolTraining: RpgTraining skill = ownedToolSkill points = 1;
ownedToolAssessment: RpgExpandedOwnedEquipmentAssessment profile = bleedProfile skill = ownedToolSkill items = [marketItem]
    quality = 'fine' approved = true evidence = 'This owned kit contains the tools required for this specific craft task';
ownedToolContext: RpgLiteContext skill = ownedToolSkill equipmentAssessment = ownedToolAssessment;
ownedToolStore: object;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 15100) { bleedProfile.equipment = [marketItem]; bleedProfile.skills = [ownedToolTraining]; return nil; }
        if (code == 15101)
        {
            event('test.owned-tool-preview'); eventValue(ownedToolContext.equipmentUseModifier(bleedProfile));
            eventValue(ownedToolContext.unavailableReason(bleedProfile)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 15102) { marketItem.storageLocation = ownedToolStore; return nil; }
        if (code == 15103)
        {
            local value = rpgLiteCheck(bleedProfile,ownedToolContext);
            event('test.owned-tool-check'); eventValue(value.status); eventValue(value.reason); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 15104) { bleedProfile.equipment = []; return nil; }
        if (code == 15105)
        {
            try { ownedToolContext.equipmentUseModifier(bleedHealer); }
            catch (RpgExpandedError error) { event('test.owned-tool-reject'); eventValue(error.reason); } return nil;
        }
        if (code == 15106) { ownedToolAssessment.missingItems = 1; ownedToolAssessment.damagePenalty = 1; return nil; }
        if (code == 15107) { ownedToolAssessment.quality = 'best'; ownedToolAssessment.techLevel = 8; return nil; }
        return inherited(context);
    }
;
