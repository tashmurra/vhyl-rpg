#include "expanded-nature-defaults.t"
#include <vhyl-rpg-expanded-equipment.t>
wildernessDependent: RpgExpandedProfile rules = bleedRules;
wildernessEquipment: RpgExpandedEquipmentAssessment quality = 'basic';
wildernessTools: RpgExpandedWildernessTools equipmentAssessment = wildernessEquipment planet = 'home' terrain = 'woodlands'
    approved = true evidence = 'Basic equipment for the local woodland conditions';
wildernessDay: RpgExpandedWildernessDay id = 'woodland-day' profile = bleedProfile skill = survivalTarget tools = wildernessTools
    dependents = [wildernessDependent] compatibleBodies = true approved = true
    evidence = 'The guide cares for one dependent in body-compatible woodland terrain on this planet for the day';
wildernessDuplicate: RpgExpandedWildernessDay id = 'another-guide-request' profile = bleedProfile skill = survivalTarget tools = wildernessTools
    dependents = [wildernessDependent] compatibleBodies = true approved = true evidence = 'Repeated daily care';
wildernessDice: object index = 0;
modify rpgRandom
    die()
    { wildernessDice.index += 1; self.draws += 1; return [4,4,1,2][(wildernessDice.index-1) % 4 + 1]; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 2300 || code == 2301)
        { local value = wildernessDay.apply(); event('test.wilderness-result'); eventValue(value.status); eventValue(value.reason); if (code == 2301) throw new RpgError(); return nil; }
        if (code == 2302)
        { local value = wildernessDay.assess(); event('test.wilderness-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.score); return nil; }
        if (code == 2303)
        {
            event('test.wilderness-state'); eventValue(bleedProfile.injury); eventValue(wildernessDependent.injury);
            eventValue(bleedProfile.wildernessDays.length()); eventValue(wildernessDependent.wildernessDays.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 2304)
        { local value = wildernessDuplicate.apply(); event('test.wilderness-result'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 2305) { wildernessTools.terrain = 'desert'; return nil; }
        if (code == 2306) { wildernessDay.compatibleBodies = nil; return nil; }
        if (code == 2307)
        {
            event('test.wilderness-injury-table'); eventValue(rpgExpandedSurvivalInjury(1,1));
            eventValue(rpgExpandedSurvivalInjury(2,2)); eventValue(rpgExpandedSurvivalInjury(2,3));
            eventValue(rpgExpandedSurvivalInjury(3,4)); eventValue(rpgExpandedSurvivalInjury(6,6)); return nil;
        }
        if (code == 2308) { wildernessTools.weatherPenalty = -2; return nil; }
        if (code == 2309)
        {
            wildernessDay.dependents = [wildernessDependent,wildernessDependent,wildernessDependent,wildernessDependent,
                wildernessDependent,wildernessDependent,wildernessDependent,wildernessDependent,wildernessDependent,wildernessDependent,wildernessDependent];
            event('test.wilderness-limit');
            try { wildernessDay.apply(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
