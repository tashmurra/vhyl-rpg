#include "expanded-phobia.t"
phobiaLowDecision: RpgExpandedLowScoreFearDecision entry = phobiaFirst row = 4 approved = true
    evidence = 'Author selects brief stun for this prohibited self-control roll';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 560)
        { phobiaPurchase.scope = 'heights'; phobiaPurchase.selfControlRating = 6;
          phobiaFirstContext.condition = 'fall-risk'; fearProfile.traits = [phobiaPurchase]; return nil; }
        if (code == 561) { phobiaFirst.lowScoreDecision = phobiaLowDecision; return nil; }
        if (code == 562)
        { local v = phobiaFirst.assess(); event('test.low-control'); eventValue(v.status); eventValue(v.reason); return nil; }
        return inherited(context);
    }
;
