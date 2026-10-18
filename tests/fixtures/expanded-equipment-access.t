#include "expanded-owned-tools.t"
toolLender: RpgExpandedProfile rules = bleedRules;
toolSite: object;
toolOtherSite: object;
toolAccess: RpgExpandedEquipmentAccess id = 'shared-kit' profile = bleedProfile owner = toolLender item = marketItem
    skill = ownedToolSkill expiresAt = 60 approved = true evidence = 'Owner permits this craft task until second sixty';
accessibleToolAssessment: RpgExpandedAccessibleEquipmentAssessment profile = bleedProfile skill = ownedToolSkill items = [marketItem]
    quality = 'fine' approved = true evidence = 'This permitted kit is adequate for the task' accessGrants = [toolAccess];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 15200)
        {
            bleedProfile.equipment = []; toolLender.equipment = [marketItem]; bleedProfile.skills = [ownedToolTraining];
            bleedProfile.equipmentSite = toolSite; toolLender.equipmentSite = toolSite;
            ownedToolContext.equipmentAssessment = accessibleToolAssessment; return nil;
        }
        if (code == 15201 || code == 15208)
        { toolAccess.grant(); if (code == 15208) throw new RpgError(); return nil; }
        if (code == 15202) { toolAccess.revoke(); return nil; }
        if (code == 15203) { rpgSpendTime(60); return nil; }
        if (code == 15204) { toolLender.equipmentSite = toolOtherSite; return nil; }
        if (code == 15205) { toolAccess.site = toolSite; marketItem.storageLocation = toolSite; return nil; }
        if (code == 15206) { bleedProfile.equipmentSite = toolOtherSite; return nil; }
        if (code == 15207) { toolLender.equipment = []; return nil; }
        if (code == 15209)
        {
            event('test.tool-access-state'); eventValue(bleedProfile.equipmentAccessGrants.length());
            eventValue(bleedProfile.equipment.length()); eventValue(toolLender.equipment.length()); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
