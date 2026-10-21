#include "expanded-fear-compound.t"
acquiredPhobia: RpgExpandedPhobia approved = true;
phobiaAward: RpgExpandedFearPhobiaAcquisition id = 'acquired-phobia' eventId = 'apparition' profile = fearProfile
    trait = acquiredPhobia approved = true evidence = 'The frightening event creates this specific new fear';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 410 || code == 411 || code == 412)
        {
            fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7;
            compoundFear.acquisition = phobiaAward; compoundFear.tableTotal = code == 410 ? 27 : code == 411 ? 39 : 40;
            if (code != 410)
            { compoundFear.episode = compoundComa; acquiredPhobia.scope = 'darkness'; acquiredPhobia.points = -15; phobiaAward.tableTotal = 35; }
            fearEventInput.initialRoll = 18; return nil;
        }
        if (code == 413)
        {
            event('test.fear-phobia-account'); eventValue(fearProfile.iq); eventValue(fearProfile.postCreationDisadvantageAllowance());
            eventValue(fearProfile.earnedPoints); eventValue(fearProfile.unspentPoints); eventValue(fearProfile.developmentRevision); return nil;
        }
        if (code == 414) { fearProfile.iq = 1; return nil; }
        if (code == 415 || code == 416) { phobiaAward.apply(); if (code == 416) throw new RpgError(); return nil; }
        return inherited(context);
    }
;
