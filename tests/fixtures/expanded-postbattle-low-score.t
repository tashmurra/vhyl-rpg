#include "expanded-postbattle-fear.t"
battleLowDecision: RpgExpandedLowScoreFearDecision entry = postbattleEvent row = 4 approved = true
    evidence = 'Author selects brief stun after the battle without inventing a failed roll';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 560)
        { fearProfile.traits = [postbattleTrait]; postbattleTrait.selfControlRating = 6;
          postbattleEvent.dangerPenalty = -4; postbattleContext.dangerPenalty = -4; return nil; }
        if (code == 561) { postbattleEvent.lowScoreDecision = battleLowDecision; return nil; }
        if (code == 562)
        { local v = postbattleEvent.assess(); event('test.low-control'); eventValue(v.status); eventValue(v.reason); return nil; }
        return inherited(context);
    }
;
