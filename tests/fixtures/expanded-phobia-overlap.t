#include "expanded-phobia.t"
secondPhobia: RpgExpandedPhobia scope = 'cats' points = -5 selfControlRating = 12 approved = true;
secondExposure: RpgExpandedPhobiaExposure id = 'cats-scene' profile = fearProfile trait = secondPhobia
    cause = fearOccurrence approved = true evidence = 'A cat and visible blood are present in the same scene';
secondContext: RpgExpandedPhobiaContext profile = fearProfile exposure = secondExposure approved = true evidence = 'The cat is perceived';
secondOccurrence: object;
secondCheck: RpgExpandedPhobiaCheck id = 'cat-first' context = secondContext occurrence = secondOccurrence;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 520 || code == 521 || code == 522)
        {
            fearProfile.traits = [phobiaPurchase,secondPhobia]; fearEventInput.initialRoll = 10;
            if (code != 522)
            { fearProfile.phobiaOverlapPolicy = code == 520 ? 'sum' : 'worst';
              fearProfile.phobiaOverlapEvidence = 'Explicit campaign ruling for concurrent shaken penalties'; }
            return nil;
        }
        if (code == 523) { secondExposure.start(); return nil; }
        if (code == 524 || code == 525) { secondCheck.resolve(); if (code == 525) throw new RpgError(); return nil; }
        if (code == 526)
        {
            event('test.phobia-overlap'); eventValue(fearProfile.phobiaExposures.length());
            eventValue(rpgLiteScore(fearProfile,phobiaSkill)); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
