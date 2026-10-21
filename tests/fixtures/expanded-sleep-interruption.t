#include "expanded-pain-sleep.t"
modify painDay duringSleep = nil;
modify rpgLedger
    afterAdvance(previous)
    {
        inherited(previous);
        if (bleedInput.code == 4800) painDay.duringSleep = true;
        return nil;
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 4800 || code == 4801)
        { rpgLiteRest(bleedProfile,10,nil,nil,true,nil); return nil; }
        if (code == 4802)
        {
            event('test.sleep-interruption'); eventValue(rpgLedger.seconds); eventValue(bleedProfile.sleepClock);
            eventValue(painDay.duringSleep ? 1 : 0); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
