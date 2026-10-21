#include "expanded-fear-event.t"
rageFirst: RpgExpandedWound id = 'rage-first' profile = fearProfile amount = 1;
rageSecond: RpgExpandedWound id = 'rage-second' profile = fearProfile amount = 2;
rageWindow: RpgExpandedRageInjuryWindow profile = fearProfile second = 0;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 900) { rageFirst.apply(); return nil; }
        if (code == 901 || code == 902)
        { rageSecond.apply(); if (code == 902) throw new RpgError(); return nil; }
        if (code == 903)
        {
            local v = rageWindow.assess(); event('test.rage-window'); eventValue(v.status); eventValue(v.reason);
            eventValue(v.injury); eventValue(v.triggered ? 1 : 0); eventValue(v.wounds.length());
            eventValue(fearProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 904) { rpgSpendTime(1); rageWindow.second = rpgLedger.seconds; return nil; }
        if (code == 905)
        { event('test.rage-threshold');
          foreach (local pair in [[10,2],[10,3],[12,3],[12,4],[1,0],[1,1]])
              eventValue(rpgExpandedRageInjuryThreshold(pair[1],pair[2]) ? 1 : 0);
          return nil; }
        if (code == 906) { rpgLiteWound(fearProfile,1); return nil; }
        return inherited(context);
    }
;
