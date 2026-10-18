#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-traits.t>
clottingTrait: RpgExpandedImpairedClotting approved = true;
modify bleedProfile traits = [clottingTrait];
clottingEpisode: RpgExpandedClottingEpisode id = 'first-wound' wound = bleedWound approved = true evidence = 'Untreated external cut';
clottingFirst: RpgExpandedClottingLoss id = 'first-minute' episode = clottingEpisode;
clottingSecond: RpgExpandedClottingLoss id = 'second-minute' episode = clottingEpisode;
clottingOtherWound: RpgExpandedWound id = 'other-cut' profile = bleedProfile amount = 1;
clottingOtherEpisode: RpgExpandedClottingEpisode id = 'other-wound' wound = clottingOtherWound
    approved = true evidence = 'A separate untreated cut';
clottingOtherLoss: RpgExpandedClottingLoss id = 'other-minute' episode = clottingOtherEpisode;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 60) { clottingEpisode.apply(); return nil; }
        if (code == 61 || code == 63 || code == 64)
        {
            if (code == 64) clottingFirst.assess(); else clottingFirst.apply();
            if (code == 63) throw new RpgError(); return nil;
        }
        if (code == 62) { clottingSecond.apply(); return nil; }
        if (code == 65) { rpgLiteHeal(bleedProfile,1); return nil; }
        if (code == 67) { clottingEpisode.torsoImpaling = true; return nil; }
        if (code == 68) { clottingOtherWound.apply(); clottingOtherEpisode.apply(); return nil; }
        if (code == 69) { clottingOtherLoss.apply(); return nil; }
        if (code == 66)
        {
            event('test.clotting-loss'); eventValue(bleedProfile.injury); eventValue(clottingEpisode.originalInjury);
            eventValue(clottingEpisode.ticks.length()); eventValue(clottingEpisode.internalLoss);
            eventValue(clottingEpisode.nextLossAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(bleedProfile.naturalRecoveryNeeded() ? 1 : 0); return nil;
        }
        return inherited(context);
    }
;
