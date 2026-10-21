#include "expanded-phobia.t"
worsePhobia: RpgExpandedPhobia scope = 'blood' points = -10 selfControlRating = 9 approved = true;
worsening: RpgExpandedFearPhobiaWorsening id = 'worsening' eventId = 'apparition' profile = fearProfile
    previous = phobiaPurchase replacement = worsePhobia related = true approved = true
    evidence = 'The incident directly involved the existing feared stimulus';
fallbackPhobia: RpgExpandedPhobia scope = 'large-water' points = -10 selfControlRating = 12 approved = true;
fallbackAward: RpgExpandedFearPhobiaAcquisition id = 'fallback' eventId = 'apparition' profile = fearProfile
    trait = fallbackPhobia approved = true evidence = 'A new fear associated with this incident';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 430)
        {
            fearProfile.traits = [phobiaPurchase]; fearProfile.creationComplete = true;
            fearProfile.disadvantageLimit = 10; fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7;
            fearEventInput.initialRoll = 10; return nil;
        }
        if (code == 431 || code == 432)
        { worsening.apply(); if (code == 432) throw new RpgError(); return nil; }
        if (code == 433)
        {
            event('test.phobia-worsening'); eventValue(fearProfile.phobiaControlNumber(phobiaPurchase));
            eventValue(fearProfile.traits.length()); eventValue(fearProfile.postCreationDisadvantageAllowance());
            eventValue(fearProfile.developmentRevision); eventValue(fearProfile.earnedPoints); eventValue(fearProfile.unspentPoints);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 434)
        { phobiaPurchase.selfControlRating = 6; fearProfile.disadvantageLimit = 20;
          worsening.replacement = nil; worsening.fallback = fallbackAward; return nil; }
        if (code == 435) { worsePhobia.selfControlRating = 6; worsening.apply(); return nil; }
        if (code == 436) { fearProfile.validateFeatures(); return nil; }
        return inherited(context);
    }
;
