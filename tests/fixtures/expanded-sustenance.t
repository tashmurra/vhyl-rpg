#include "expanded-fixed-beliefs.t"
sustenanceTrait: RpgExpandedSustenanceRequirement scope = 'mineral-bath' rarity = 'common' frequency = 'daily'
    requirementKind = 'environment' requirementText = 'A bath in the authored mineral solution'
    approved = true evidence = 'The author confirms availability and life-support suitability';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 11600)
        {
            event('test.sustenance-price');
            foreach (local rarity in ['rare','occasional','common','very-common'])
                foreach (local frequency in ['continuous','hourly','daily','weekly','monthly','seasonal','yearly'])
                {
                    eventValue(rpgExpandedSustenanceCost(rarity,nil,frequency));
                    eventValue(rpgExpandedSustenanceCost(rarity,true,frequency));
                }
            return nil;
        }
        if (code == 11601)
        {
            event('test.sustenance-schedule');
            foreach (local frequency in ['continuous','hourly','daily','weekly','monthly','seasonal','yearly'])
            {
                local row = rpgExpandedSustenanceSchedule(frequency); eventValue(row[3]); eventValue(row[4]); eventValue(row[5]);
            }
            return nil;
        }
        if (code == 11602)
        {
            bleedProfile.traits = [sustenanceTrait]; rpgExpandedValidate(bleedProfile);
            local copy = rpgExpandedTemplateTraits.copy(sustenanceTrait);
            event('test.sustenance-definition'); eventValue(sustenanceTrait.creationCost());
            eventValue(sustenanceTrait.requiredContactSeconds()); eventValue(copy.creationCost());
            eventValue(copy.requiredContactSeconds()); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 11603) { sustenanceTrait.frequency = 'yearly'; return nil; }
        return inherited(context);
    }
;
