#include "expanded-sustenance-injury.t"
sustenanceContinuous: RpgExpandedContinuousSustenanceAccess id = 'initial-atmosphere' profile = bleedProfile requirement = sustenanceTrait
    approved = true evidence = 'The required atmosphere is present' boundaryOrder = 'access-first';
sustenanceContinuousReturn: RpgExpandedContinuousSustenanceAccess id = 'returned-atmosphere' profile = bleedProfile requirement = sustenanceTrait
    episode = sustenanceEpisode approved = true evidence = 'The required atmosphere is restored' boundaryOrder = 'access-first';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 12600)
        { sustenanceTrait.frequency = 'continuous'; bleedProfile.traits = [sustenanceTrait]; sustenanceContinuous.begin(); return nil; }
        if (code == 12601 || code == 12602)
        { sustenanceContinuous.lose(sustenanceEpisode); if (code == 12602) throw new RpgError(); return nil; }
        if (code == 12603) { rpgSpendTime(60); return nil; }
        if (code == 12604 || code == 12605)
        { sustenanceContinuousReturn.begin(); if (code == 12605) throw new RpgError(); return nil; }
        if (code == 12606)
        {
            event('test.sustenance-continuous'); eventValue(bleedProfile.continuousSustenanceAccess.length());
            eventValue(bleedProfile.sustenanceDeprivations.length()); eventValue(sustenanceContinuous.endedAt);
            eventValue(sustenanceEpisode.restoration == nil ? 0 : 1); eventValue(bleedProfile.injury);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
