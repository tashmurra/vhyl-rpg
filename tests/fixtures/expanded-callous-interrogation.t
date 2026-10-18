#include "expanded-interrogation.t"
#include <vhyl-rpg-expanded-traits.t>
questionCallousness: RpgExpandedCallousness approved = true;
modify questionActor traits = [questionCallousness];
modify rpgLedger
    afterAdvance(previous)
    {
        inherited(previous);
        if (bleedInput.code == 4205) questionRequest.pastVictim = !questionRequest.pastVictim;
        return nil;
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 4200) { questionRequest.pastVictim = true; return nil; }
        if (code == 4201) { questionCallousness.mitigated = true; return nil; }
        if (code == 4202) { questionActor.traits = []; return nil; }
        if (code == 4203)
        {
            event('test.callous-question-binding');
            try { questionRequest.apply(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 4204)
        {
            local value = questionRequest.assess(); event('test.callous-question-score');
            eventValue(value.actorScore); eventValue(value.modifier); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 4205) { questionRequest.apply(); return nil; }
        return inherited(context);
    }
;
