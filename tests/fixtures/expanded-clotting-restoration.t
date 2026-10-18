#include "expanded-clotting-care.t"
clottingRestoration: RpgExpandedClottingRestoration eventId = 'restoration-effect' episode = clottingEpisode
    restoredHP = 2 stopsBleeding = true approved = true occurredAt = 120
    effectEvidence = 'An authored supernatural effect restores two internal-loss HP and stops the source';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 80 && code <= 82)
        {
            if (code == 81) clottingRestoration.assess(); else clottingRestoration.apply();
            if (code == 82) throw new RpgError(); return nil;
        }
        if (code == 83) { clottingRestoration.restoredHP = 1; clottingRestoration.stopsBleeding = nil; return nil; }
        if (code == 84) { clottingRestoration.restoredHP = 0; return nil; }
        if (code == 85) { clottingRestoration.occurredAt = 0; return nil; }
        if (code == 88) { clottingRestoration.occurredAt = rpgLedger.seconds; return nil; }
        if (code == 86)
        {
            event('test.clotting-restoration'); eventValue(bleedProfile.injury); eventValue(clottingEpisode.internalLoss);
            eventValue(clottingEpisode.restoredInternal); eventValue(clottingEpisode.care);
            eventValue(clottingEpisode.nextLossAt); eventValue(bleedProfile.clottingProtectedInjury());
            eventValue(bleedProfile.clottingRestorations.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
