#include "expanded-fear-event.t"
modify fearProfile
    knockdownDispatches = 0
    applyInjuryKnockdown(result,modifier)
    { self.knockdownDispatches += 1; return inherited(result,modifier); }
;
dispatchWound: RpgExpandedWound id = 'dispatch-wound' profile = fearProfile amount = 6;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 940 || code == 941)
        { dispatchWound.apply(); if (code == 941) throw new RpgError(); return nil; }
        if (code == 942)
        { event('test.knockdown-dispatch'); eventValue(fearProfile.injury); eventValue(fearProfile.stunned ? 1 : 0);
          eventValue(fearProfile.unconscious ? 1 : 0); eventValue(fearProfile.posture);
          eventValue(fearProfile.knockdownDispatches); eventValue(fearProfile.expandedWounds.length());
          eventValue(rpgRandom.draws); return nil; }
        if (code == 943) { fearEventInput.initialRoll = 8; return nil; }
        return inherited(context);
    }
;
