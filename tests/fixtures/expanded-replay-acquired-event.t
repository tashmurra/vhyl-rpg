#include "expanded-intrusive-replay.t"
acquiredReplayInput: object rolls = 0;
acquiredReplayScene: object;
acquiredReplayContext: RpgExpandedFearContext profile = fearProfile approved = true
    evidence = 'A later alarm recalls the first frightening encounter'
    intrusiveReplayContent = 'The character relives the original evacuation';
acquiredReplayEvent: RpgExpandedFearEvent id = 'later-alarm' occurrence = acquiredReplayScene context = acquiredReplayContext;
acquiredReplayStun: RpgExpandedFearStun id = 'later-alarm-stun' context = acquiredReplayContext tableTotal = 4
    approved = true evidence = 'The later fear result requires brief stun';
modify rpgRandom
    roll()
    {
        self.draws += 3; acquiredReplayInput.rolls += 1;
        return [18,15,11,3,6][acquiredReplayInput.rolls];
    }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1085)
        { mentalAward.trait = rpgExpandedTemplateTraits.configured('intrusive-replay',2,nil,['evacuation memories']);
          mentalAward.tableTotal = 23; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; return nil; }
        if (code == 1086) { ownedFearEvent.resolve(); return nil; }
        if (code == 1087 || code == 1092)
        { ownedFearEvent.applyConsequence(mentalAward); if (code == 1092) throw new RpgError(); return nil; }
        if (code == 1088 || code == 1093)
        { acquiredReplayEvent.resolve(); if (code == 1093) throw new RpgError(); return nil; }
        if (code == 1089)
        {
            event('test.acquired-replay'); eventValue(fearProfile.fearEvents.length());
            eventValue(fearProfile.traits.length()); eventValue(fearProfile.postCreationDisadvantageAllowance());
            eventValue(fearProfile.earnedPoints); eventValue(fearProfile.unspentPoints);
            eventValue(fearProfile.intrusiveReplayOccurrences.length()); eventValue(fearProfile.healthAttributeModifier(replayContext));
            eventValue(rpgRandom.draws); eventValue(fearProfile.mentalStun ? 1 : 0); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1090 || code == 1094)
        { acquiredReplayEvent.applyConsequence(acquiredReplayStun); if (code == 1094) throw new RpgError(); return nil; }
        if (code == 1091) { rpgSpendTime(1); return nil; }
        if (code == 1095) { rpgSpendTime(119); return nil; }
        return inherited(context);
    }
;
