#include "expanded-fixed-beliefs.t"
beliefPrivate: RpgExpandedFixedBeliefKnowledge id = 'private-truth' profile = bleedProfile belief = beliefOne
    truthConfirmed = true characterAware = true approved = true evidence = 'Private author confirmation';
beliefPublic: RpgExpandedFixedBeliefKnowledge id = 'public-recognition' profile = bleedProfile belief = beliefOne
    previous = beliefPrivate truthConfirmed = true playersRecognize = true approved = true evidence = 'Other players recognized the truth';
beliefBasis: RpgExpandedBuyoffBasis owner = bleedProfile trait = beliefOne originalBonus = 10 approved = true
    evidence = 'Original award recorded by the author';
beliefBuyoff: RpgExpandedFixedBeliefRevelationBuyoff knowledge = beliefPrivate approved = true evidence = 'Approved removal following recognition';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 11400)
        {
            bleedProfile.traits = [beliefOne]; bleedProfile.buyoffBases = [beliefBasis];
            bleedProfile.developmentOpen = true; bleedProfile.earnedPoints = 15; bleedProfile.unspentPoints = 15;
            beliefPrivate.record(); return nil;
        }
        if (code == 11401)
        {
            local value = beliefBuyoff.assess(); event('test.belief-revelation-preview');
            eventValue(value.status); eventValue(value.reason); eventValue(value.points); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 11402) { beliefPublic.record(); beliefBuyoff.knowledge = beliefPublic; return nil; }
        if (code == 11403 || code == 11404)
        { beliefBuyoff.apply(); if (code == 11404) throw new RpgError(); return nil; }
        if (code == 11405)
        {
            event('test.belief-revelation-state'); eventValue(bleedProfile.traits.length()); eventValue(bleedProfile.earnedPoints);
            eventValue(bleedProfile.unspentPoints); eventValue(bleedProfile.fixedBeliefKnowledge.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 11406) { beliefPrivate.truthConfirmed = nil; return nil; }
        if (code == 11407) { bleedProfile.unspentPoints = 9; return nil; }
        return inherited(context);
    }
;
