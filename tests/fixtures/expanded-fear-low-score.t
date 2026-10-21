#include "expanded-fear-stress.t"
lowDecision: RpgExpandedLowScoreFearDecision entry = ownedFearEvent row = 4 approved = true
    evidence = 'Author ruling: freeze briefly when no initial roll is permitted';
lowReroll: RpgExpandedFearAdjudication id = 'invalid-reroll' entry = ownedFearEvent mode = 'reroll'
    approved = true evidence = 'Attempting to reroll a result without a rolled margin';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 550) { fearProfile.willAdjustment = -8; return nil; }
        if (code == 551) { ownedFearEvent.lowScoreDecision = lowDecision; return nil; }
        if (code == 552) { lowDecision.voiceStress = 'none'; return nil; }
        if (code == 553) { lowDecision.voiceStress = 'check'; return nil; }
        if (code == 554) { lowDecision.row = 5; ownedFearEvent.assess(); return nil; }
        if (code == 555)
        { local v = lowReroll.assess(); event('test.low-reroll'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 556)
        { local v = ownedFearEvent.result; event('test.low-score'); eventValue(v == nil ? nil : v.reason);
          eventValue(v == nil || v.check == nil ? 0 : 1); eventValue(v == nil ? nil : v.tableRoll);
          eventValue(v == nil ? nil : v.tableTotal); eventValue(v == nil ? nil : v.row);
          eventValue(rpgRandom.draws); eventValue(fearProfile.phantomVoiceOccurrences.length()); return nil; }
        return inherited(context);
    }
;
