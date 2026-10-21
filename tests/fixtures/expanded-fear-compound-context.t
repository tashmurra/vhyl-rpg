#include "expanded-fear-compound.t"
compoundDanger: RpgExpandedDangerAvoidance approved = true;
compoundDangerAward: RpgExpandedFearMentalAcquisition id = 'compound-danger' eventId = 'apparition'
    profile = fearProfile trait = compoundDanger approved = true evidence = 'The event causes lasting avoidance of physical danger';
compoundLowDecision: RpgExpandedLowScoreFearDecision entry = ownedFearEvent row = 27 approved = true
    evidence = 'Recorded compound faint and mental acquisition with no prohibited initial roll';
modify FearTestAction
    exec(context)
    {
        if (fearInput.code == 1264)
        {
            fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; fearProfile.willAdjustment = -8;
            fearContext.physicalRisk = true; ownedFearEvent.lowScoreDecision = compoundLowDecision;
            compoundFear.tableTotal = 27; compoundFear.acquisition = compoundDangerAward; return nil;
        }
        return inherited(context);
    }
;
