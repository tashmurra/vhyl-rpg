#include "expanded-intrusive-replay.t"
replaySecondStressor: object;
replaySecond: RpgExpandedIntrusiveReplayOccurrence id = 'second-alarm' profile = fearProfile stressor = replaySecondStressor
    approved = true evidence = 'Another independently stressful interruption'
    content = 'The memory reappears while the first episode remains active';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1070 || code == 1071)
        { fearProfile.intrusiveReplayOverlapPolicy = code == 1070 ? 'worst' : 'sum';
          fearProfile.intrusiveReplayOverlapEvidence = 'The author records the campaign treatment of overlapping skill penalties'; return nil; }
        if (code == 1072 || code == 1073)
        { replaySecond.resolve(); if (code == 1073) throw new RpgError(); return nil; }
        if (code == 1074)
        {
            event('test.replay-overlap'); eventValue(fearProfile.intrusiveReplayOccurrences.length());
            eventValue(fearProfile.healthAttributeModifier(replayContext)); eventValue(fearProfile.intrusiveReplaySeverity());
            eventValue(replayOccurrence.expiresAt); eventValue(replaySecond.expiresAt);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1075) { rpgSpendTime(2); return nil; }
        if (code == 1076) { fearProfile.intrusiveReplayOverlapPolicy = nil; fearProfile.intrusiveReplayOverlapEvidence = nil; return nil; }
        if (code == 1077) { replaySecond.overlapPolicy = 'sum'; replaySecond.assess(); return nil; }
        if (code == 1080)
        { mentalAward.trait = rpgExpandedTemplateTraits.configured('intrusive-replay',2,nil,['evacuation memories']);
          mentalAward.tableTotal = 23; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; return nil; }
        if (code == 1081) { mentalAward.trait.replayType = 'Changed'; mentalAward.assess(); return nil; }
        if (code == 1082)
        { event('test.replay-acquisition'); eventValue(fearProfile.traits.length());
          eventValue(fearProfile.postCreationDisadvantageAllowance()); eventValue(fearProfile.earnedPoints);
          eventValue(fearProfile.unspentPoints); eventValue(fearProfile.healthAttributeModifier(replayContext));
          eventValue(rpgRandom.draws); return nil; }
        return inherited(context);
    }
;
