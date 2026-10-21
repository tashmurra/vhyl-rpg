#include "expanded.t"
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code >= 16000 && code <= 16009)
        {
            local susceptible = code == 16003 || code == 16004 || code == 16009;
            local moving = code != 16008;
            local sea = code != 16007;
            local stabilized = code == 16005 || code == 16009;
            local day = code == 16006 || code == 16009 ? 2 : 1;
            local roll = code == 16000 ? 10 : code == 16001 ? 11 : code == 16002 ? 16
                : code == 16003 ? 3 : code == 16004 ? 11 : 10;
            local value = rpgExpandedSeasickness(10,susceptible,moving,sea,stabilized,day,roll);
            event('test.seasickness'); eventValue(value.status); eventValue(value.checkRequired);
            eventValue(value.score); eventValue(value.penalty); eventValue(value.vomits); eventValue(rpgRandom.draws);
            return nil;
        }
        return inherited(context);
    }
;
