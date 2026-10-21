#include "expanded-fear-event-traits.t"
compoundFaint: RpgExpandedFearFaint id = 'apparition' context = fearContext tableTotal = 18 approved = true
    evidence = 'The event joins a faint and a lasting belief';
compoundComa: RpgExpandedFearComa id = 'apparition' context = fearContext tableTotal = 29 approved = true
    evidence = 'The event joins a coma and a lasting belief';
compoundFear: RpgExpandedFearBeliefCompound id = 'apparition' context = fearContext acquisition = eventBeliefAward episode = compoundFaint;
modify rpgRandom die() { self.draws += 1; return 1; };
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 340 || code == 341)
        {
            fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7;
            fearEventInput.initialRoll = 18; fearEventInput.tableRoll = 18;
            if (code == 341)
            { compoundFear.tableTotal = 38; compoundFear.episode = compoundComa;
              eventBeliefAward.tableTotal = 34; eventBelief.level = 3; }
            return nil;
        }
        if (code == 478 || code == 479)
        {
            fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7;
            if (code == 478) { compoundFear.tableTotal = 27; eventBeliefAward.tableTotal = 23; }
            else { compoundFear.tableTotal = 39; compoundFear.episode = compoundComa; eventBeliefAward.tableTotal = 35; eventBelief.level = 3; }
            return nil;
        }
        if (code == 342 || code == 343)
        { compoundFear.apply(); if (code == 343) throw new RpgError(); return nil; }
        if (code == 344)
        {
            event('test.fear-compound'); eventValue(fearProfile.fearBeliefCompounds.length()); eventValue(fearProfile.traits.length());
            eventValue(fearProfile.unconscious ? 1 : 0); eventValue(fearProfile.injury); eventValue(fearProfile.developmentRevision);
            eventValue(fearProfile.earnedPoints); eventValue(fearProfile.unspentPoints); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 345) { ownedFearEvent.applyConsequence(compoundFear); return nil; }
        if (code == 346) { eventBeliefAward.approved = nil; compoundFear.apply(); return nil; }
        if (code == 347) { compoundFaint.tableTotal = 17; compoundFear.apply(); return nil; }
        if (code == 1260) { compoundFear.episode.approved = nil; compoundFear.apply(); return nil; }
        if (code == 1261) { compoundFear.acquisition.apply(); return nil; }
        if (code == 1262) { compoundFear.episode.apply(); return nil; }
        if (code == 1263)
        { local value = compoundFear.assess(); event('test.compound-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        return inherited(context);
    }
;
