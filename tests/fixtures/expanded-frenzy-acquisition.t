#include "expanded-fear-mental.t"
acquiredFrenzy: RpgExpandedFrenzy approved = true;
worseFrenzy: RpgExpandedFrenzy approved = true selfControlRating = 9;
modify FearTestAction
    exec(context)
    {
        if (fearInput.code == 1480)
        {
            mentalAward.trait = acquiredFrenzy; mentalAward.tableTotal = 23;
            mentalWorsening.previous = acquiredFrenzy; mentalWorsening.replacement = worseFrenzy;
            fearProfile.creationComplete = true; fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; return nil;
        }
        if (fearInput.code == 1481)
        {
            event('test.frenzy-acquisition'); eventValue(fearProfile.traits.length());
            eventValue(fearProfile.postCreationDisadvantageAllowance()); eventValue(fearProfile.earnedPoints);
            eventValue(fearProfile.unspentPoints); return nil;
        }
        return inherited(context);
    }
;
