#include "expanded-fear-stress.t"
postbattleTrait: RpgExpandedPostbattleStress approved = true selfControlRating = 12;
postbattleContext: RpgExpandedPostbattleFearContext profile = fearProfile trait = postbattleTrait approved = true
    evidence = 'The last opponent has withdrawn and the battle is over';
postbattleEvent: RpgExpandedPostbattleFearEvent id = 'battle-ended' occurrence = fearOccurrence context = postbattleContext
    trait = postbattleTrait battleEnded = true;
postbattleStun: RpgExpandedFearStun id = 'battle-ended' context = postbattleContext approved = true
    evidence = 'The retained postbattle table selection requires brief stun';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 370 || code == 371)
        { fearProfile.traits = [postbattleTrait,eventVoices]; fearEventInput.initialRoll = code == 370 ? 13 : 12; return nil; }
        if (code == 372 || code == 373)
        { postbattleEvent.resolve(); if (code == 373) throw new RpgError(); return nil; }
        if (code == 374)
        {
            local v = postbattleEvent.result; event('test.postbattle-fear'); eventValue(v == nil ? nil : v.score);
            eventValue(v == nil ? nil : v.row); eventValue(fearProfile.phantomVoiceOccurrences.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 375) { postbattleEvent.applyConsequence(postbattleStun); return nil; }
        if (code == 376) { fearProfile.willAdjustment = 5; return nil; }
        if (code == 377) { postbattleEvent.battleEnded = nil; return nil; }
        return inherited(context);
    }
;
