#include "expanded-fishing-forage.t"
foragingDay: RpgExpandedForagingDay id = 'gathering-day' profile = bleedProfile approved = true
    evidence = 'The party spends this whole day gathering food instead of traveling';
dayHikingSkill: RpgLiteSkill id = 'hiking' attribute = rpgHT difficulty = 1 defaultPenalty = -5;
dayHiking: RpgExpandedHikingAttempt id = 'travel' members = [[bleedProfile,dayHikingSkill,0,nil]] approved = true evidence = 'Ordinary walking route';
dayMarchInterval: object;
dayMarch: RpgExpandedMarchHour id = 'march' profile = bleedProfile interval = dayMarchInterval
    approved = true evidence = 'One ordinary marching hour';
dayPlant1: RpgExpandedPlantForageAttempt id = 'day-plant-1' profile = bleedProfile site = plantSite skill = plantNaturalist approved = true evidence = 'Matching local plant search';
dayFish1: RpgExpandedFishingForageAttempt id = 'day-fish-1' profile = bleedProfile site = plantSite skill = fishingSkill tools = fishingTools approved = true evidence = 'Fishing in the local river';
dayPlant2: RpgExpandedPlantForageAttempt id = 'day-plant-2' profile = bleedProfile site = plantSite skill = plantNaturalist approved = true evidence = 'Matching local plant search';
dayFish2: RpgExpandedFishingForageAttempt id = 'day-fish-2' profile = bleedProfile site = plantSite skill = fishingSkill tools = fishingTools approved = true evidence = 'Fishing in the local river';
dayPlant3: RpgExpandedPlantForageAttempt id = 'day-plant-3' profile = bleedProfile site = plantSite skill = plantNaturalist approved = true evidence = 'Matching local plant search';
dayFish3: RpgExpandedFishingForageAttempt id = 'day-fish-3' profile = bleedProfile site = plantSite skill = fishingSkill tools = fishingTools approved = true evidence = 'Fishing in the local river';
dayPlant4: RpgExpandedPlantForageAttempt id = 'day-plant-4' profile = bleedProfile site = plantSite skill = plantNaturalist approved = true evidence = 'Matching local plant search';
dayFish4: RpgExpandedFishingForageAttempt id = 'day-fish-4' profile = bleedProfile site = plantSite skill = fishingSkill tools = fishingTools approved = true evidence = 'Fishing in the local river';
dayPlant5: RpgExpandedPlantForageAttempt id = 'day-plant-5' profile = bleedProfile site = plantSite skill = plantNaturalist approved = true evidence = 'Matching local plant search';
dayFish5: RpgExpandedFishingForageAttempt id = 'day-fish-5' profile = bleedProfile site = plantSite skill = fishingSkill tools = fishingTools approved = true evidence = 'Fishing in the local river';
dayPlant6: RpgExpandedPlantForageAttempt id = 'day-plant-6' profile = bleedProfile site = plantSite skill = plantNaturalist approved = true evidence = 'Matching local plant search';
dayFish6: RpgExpandedFishingForageAttempt id = 'day-fish-6' profile = bleedProfile site = plantSite skill = fishingSkill tools = fishingTools approved = true evidence = 'Fishing in the local river';
dayForageInput: object plantIndex = 0 fishIndex = 0;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 2100 || code == 2106)
        {
            local value = foragingDay.reserve(); event('test.foraging-day'); eventValue(value.status); eventValue(value.reason);
            if (code == 2106) throw new RpgError(); return nil;
        }
        if (code == 2101 || code == 2102)
        {
            local attempts = code == 2101 ? [dayFish1,dayFish2,dayFish3,dayFish4,dayFish5,dayFish6]
                : [dayPlant1,dayPlant2,dayPlant3,dayPlant4,dayPlant5,dayPlant6];
            local index = 0;
            if (code == 2101) { dayForageInput.fishIndex += 1; index = dayForageInput.fishIndex; }
            else { dayForageInput.plantIndex += 1; index = dayForageInput.plantIndex; }
            local value = attempts[index].resolve(); event('test.foraging-day-roll'); eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 2104 || code == 2105)
        { local value = code == 2104 ? dayHiking.resolve() : dayMarch.apply(); event('test.foraging-day-travel'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 2107) { rpgSpendTime(1); return nil; }
        if (code == 2108)
        {
            event('test.foraging-day-state'); eventValue(bleedProfile.foragingDays.length());
            eventValue(bleedProfile.plantForageAttempts.length()); eventValue(bleedProfile.animalFoodForageAttempts.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
