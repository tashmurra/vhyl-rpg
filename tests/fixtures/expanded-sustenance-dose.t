#include "expanded-sustenance-injury.t"
sustenanceSupply: RpgExpandedSustenanceStock id = 'mineral-dose' requirementScope = 'mineral-bath' quantity = 1;
sustenanceDose: RpgExpandedSustenanceDose id = 'first-dose' episode = sustenanceEpisode stock = sustenanceSupply
    approved = true evidence = 'The subject ingests one sufficient dose of the authored substance' boundaryOrder = 'access-first';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 12000)
        {
            sustenanceTrait.requirementKind = 'substance'; bleedProfile.equipment = [sustenanceSupply];
            bleedProfile.traits = [sustenanceTrait]; sustenanceEpisode.begin(); return nil;
        }
        if (code == 12001)
        {
            local value = sustenanceDose.assess(); event('test.sustenance-dose-preview');
            eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 12002 || code == 12003)
        { sustenanceDose.apply(); if (code == 12003) throw new RpgError(); return nil; }
        if (code == 12004)
        {
            event('test.sustenance-dose-state'); eventValue(sustenanceSupply.quantity); eventValue(bleedProfile.equipment.length());
            eventValue(sustenanceEpisode.restoration == nil ? 0 : 1); eventValue(bleedProfile.injury);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 12005) { sustenanceDose.boundaryOrder = 'injury-first'; return nil; }
        if (code == 12006) { sustenanceSupply.quantity = 0; return nil; }
        return inherited(context);
    }
;
