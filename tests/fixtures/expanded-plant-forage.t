#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-exploration.t>
plantSite: RpgExpandedForageSite id = 'woods' plantsAvailable = true evidence = 'Edible temperate woodland plants are available';
plantOtherSite: RpgExpandedForageSite id = 'other-woods' plantsAvailable = true evidence = 'Another woodland contains edible plants';
plantNaturalist: RpgLiteSkill id = 'naturalist' attribute = rpgIQ difficulty = 2 defaultPenalty = -6 specialty = 'home-planet';
plantSurvival: RpgLiteSkill id = 'survival' attribute = rpgPerception difficulty = 1 defaultPenalty = -5 specialty = 'woodlands';
plantTraining: RpgTraining skill = plantNaturalist points = 12;
plantOtherTraining: RpgTraining skill = plantSurvival points = 4;
modify bleedProfile skills = [plantTraining,plantOtherTraining];
plantAttempt: RpgExpandedPlantForageAttempt id = 'plants-one' profile = bleedProfile site = plantSite skill = plantNaturalist
    approved = true evidence = 'Travel-day plant search using knowledge of the local planet';
plantAlternate: RpgExpandedPlantForageAttempt id = 'plants-two' profile = bleedProfile site = plantSite skill = plantSurvival
    approved = true evidence = 'Travel-day plant search using the matching woodland specialty';
plantOccurrence: object;
plantPoison: RpgExpandedForagePoisoning id = 'plant-poison' occurrence = plantOccurrence forager = bleedProfile
    party = [bleedProfile] approved = true ordinarySusceptibility = true evidence = 'The lone forager consumed plants from the recorded forage check';
modify rpgRandom die() { self.draws += 1; return 4; };
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1600 || code == 1601)
        { plantAttempt.resolve(); if (code == 1601) throw new RpgError(); return nil; }
        if (code == 1602)
        { local value = plantAttempt.assess(); event('test.plant-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 1603)
        {
            event('test.plant-owned'); eventValue(bleedProfile.plantForageAttempts.length()); eventValue(rpgRandom.draws);
            eventValue(rpgLedger.seconds); eventValue(plantAttempt.result == nil || plantAttempt.result.forage == nil ? nil : plantAttempt.result.forage.meals);
            eventValue(bleedProfile.injury); return nil;
        }
        if (code == 1604)
        { local value = plantAlternate.resolve(); event('test.plant-alternate'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 1605) { rpgSpendTime(86400); return nil; }
        if (code == 1606) { bleedInput.forcedRoll = 18; return nil; }
        if (code == 1607)
        { if (plantPoison.foragingCheck == nil) plantPoison.foragingCheck = plantAttempt.result.forage.check; plantPoison.apply(); return nil; }
        if (code == 1608) { plantSurvival.attribute = rpgIQ; return nil; }
        if (code == 1609) { plantAlternate.site = plantOtherSite; return nil; }
        if (code == 1610)
        {
            event('test.plant-invalid');
            try { plantAlternate.resolve(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
