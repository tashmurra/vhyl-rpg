#include "expanded-owned-tools.t"
purchasedToolkit: RpgExpandedToolkit id = 'fine-work-kit' quality = 'fine' baseCost = 10 techLevel = 3 weight = 100
    supportedSkills = [ownedToolSkill] approved = true evidence = 'Campaign adopts the typical fine-kit multiplier for this craft kit';
toolkitSale: RpgExpandedAcquisition profile = bleedProfile item = purchasedToolkit available = true permitted = true;
purchasedToolkitAssessment: RpgExpandedToolkitAssessment toolkit = purchasedToolkit profile = bleedProfile skill = ownedToolSkill
    items = [purchasedToolkit] quality = 'fine' techLevel = 3 approved = true evidence = 'The purchased kit is adequate for this work';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 15300)
        {
            bleedProfile.money = 250; bleedProfile.skills = [ownedToolTraining]; ownedToolContext.equipmentAssessment = purchasedToolkitAssessment;
            event('test.toolkit-prices'); foreach (local quality in ['basic','good','fine']) eventValue(rpgExpandedToolkitBaseline(10,quality)); return nil;
        }
        if (code == 15301 || code == 15302)
        { toolkitSale.acquire(); if (code == 15302) throw new RpgError(); return nil; }
        if (code == 15303)
        { event('test.toolkit-purchase'); eventValue(bleedProfile.money); eventValue(bleedProfile.equipment.length()); eventValue(purchasedToolkit.cost); eventValue(rpgRandom.draws); return nil; }
        if (code == 15304 || code == 15305)
        {
            if (code == 15304) purchasedToolkitAssessment.quality = 'best';
            else purchasedToolkit.quality = 'best';
            try { ownedToolContext.equipmentUseModifier(bleedProfile); }
            catch (RpgExpandedError error) { event('test.toolkit-reject'); eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
