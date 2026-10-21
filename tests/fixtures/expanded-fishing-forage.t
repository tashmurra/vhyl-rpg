#include "expanded-plant-forage.t"
#include <vhyl-rpg-expanded-equipment.t>
fishingSkill: RpgLiteSkill id = 'fishing' attribute = rpgPerception difficulty = 0 defaultPenalty = -4;
fishingTraining: RpgTraining skill = fishingSkill points = 1;
modify bleedProfile skills = [plantTraining,plantOtherTraining,fishingTraining];
modify plantSite waterAvailable = true;
fishingEquipment: RpgExpandedEquipmentAssessment quality = 'basic';
fishingTools: RpgExpandedFishingTools equipmentAssessment = fishingEquipment approved = true
    evidence = 'A usable hook and line are available for the fish in this river';
fishingAttempt: RpgExpandedFishingForageAttempt id = 'plants-one' profile = bleedProfile site = plantSite
    skill = fishingSkill tools = fishingTools approved = true evidence = 'Fishing alongside the travel-day river route';
fishingAlternate: RpgExpandedFishingForageAttempt id = 'fish-two' profile = bleedProfile site = plantSite
    skill = fishingSkill tools = fishingTools approved = true evidence = 'Another fishing request on the same travel day';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1700 || code == 1701)
        {
            local value = fishingAttempt.resolve(); event('test.fishing-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 1701) throw new RpgError(); return nil;
        }
        if (code == 1702)
        {
            local value = fishingAttempt.assess(); event('test.fishing-preview'); eventValue(value.status);
            eventValue(value.reason); eventValue(value.score); return nil;
        }
        if (code == 1703)
        {
            event('test.fishing-owned'); eventValue(bleedProfile.animalFoodForageAttempts.length());
            eventValue(bleedProfile.plantForageAttempts.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            eventValue(fishingAttempt.result == nil || fishingAttempt.result.forage == nil ? nil : fishingAttempt.result.forage.meals);
            return nil;
        }
        if (code == 1704)
        { local value = fishingAlternate.resolve(); event('test.fishing-alternate'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 1705) { rpgSpendTime(86399); return nil; }
        if (code == 1706) { rpgSpendTime(1); return nil; }
        if (code == 1707) { bleedProfile.skills = [plantTraining,plantOtherTraining]; return nil; }
        if (code == 1708) { fishingEquipment.quality = 'improvised'; return nil; }
        if (code == 1709) { plantSite.waterAvailable = nil; return nil; }
        if (code == 1710) { fishingEquipment.quality = 'none'; return nil; }
        if (code == 1711) { fishingEquipment.quality = 'fine'; return nil; }
        if (code == 1712)
        {
            event('test.fishing-binding');
            try { fishingAttempt.resolve(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
