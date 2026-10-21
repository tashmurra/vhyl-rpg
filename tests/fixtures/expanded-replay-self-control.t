#include "expanded-intrusive-replay.t"
replayControlTrait: RpgExpandedSelfSacrifice approved = true selfControlRating = 6;
replayControlPerson: RpgLiteProfile;
replayOtherAction: object;
replaySelfAction: object;
replayControl: RpgExpandedSelfSacrificeTrigger id = 'shelter-conflict' profile = fearProfile trait = replayControlTrait
    trigger = replayStressor person = replayControlPerson competingNeeds = true
    otherFirstActions = [replayOtherAction] selfFirstActions = [replaySelfAction]
    stressRelation = 'stress-related' evidence = 'The actor is stressed by competing shelter needs'
    intrusiveReplayContent = 'A remembered evacuation displaces the current shelter scene';
replayControlInput: object controlRoll = 13 rolls = 0;
replayControlVoices: RpgExpandedPhantomVoices approved = true;
modify rpgRandom
    roll()
    { self.draws += 3; replayControlInput.rolls += 1; return replayControlInput.rolls == 1 ? replayControlInput.controlRoll : 6; }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1020)
        { fearProfile.traits = [replayControlTrait,rpgExpandedTemplateTraits.configured('intrusive-replay',2,nil,['evacuation memories'])]; return nil; }
        if (code == 1021 || code == 1022)
        { replayControl.resolve(); if (code == 1022) throw new RpgError(); return nil; }
        if (code == 1023)
        {
            event('test.replay-control'); eventValue(fearProfile.selfControlTriggers.length());
            eventValue(fearProfile.intrusiveReplayOccurrences.length()); eventValue(fearProfile.phantomVoiceOccurrences.length());
            eventValue(replayControl.active ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1024) { replayControlInput.controlRoll = 6; return nil; }
        if (code == 1025) { fearProfile.traits = fearProfile.traits + [replayControlVoices]; return nil; }
        if (code == 1026) { replayControl.stressRelation = 'unrelated'; return nil; }
        if (code == 1027) { replayControl.intrusiveReplayContent = nil; return nil; }
        if (code == 1028) { replayControl.giveIn = true; return nil; }
        if (code == 1029)
        { fearRules.pointFundedSelfControl = true; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; replayControl.buySuccess = true; return nil; }
        if (code == 1030)
        { event('test.replay-control-points'); eventValue(fearProfile.earnedPoints); eventValue(fearProfile.unspentPoints); return nil; }
        return inherited(context);
    }
;
