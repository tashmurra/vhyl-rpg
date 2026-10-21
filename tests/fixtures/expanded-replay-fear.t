#include "expanded-intrusive-replay.t"
replayFearInput: object initial = 11 rolls = 0 low = nil;
replayFearVoice: RpgExpandedPhantomVoices approved = true;
replayFearDecision: RpgExpandedLowScoreFearDecision entry = ownedFearEvent row = 4 approved = true
    evidence = 'The author selects brief stun and a separate replay check at the prohibited-roll boundary'
    replayStress = 'check';
modify rpgRandom
    roll()
    {
        self.draws += 3; replayFearInput.rolls += 1;
        if (replayFearInput.low) return 6;
        if (replayFearInput.rolls == 1) return replayFearInput.initial;
        if (replayFearInput.initial > 10 && replayFearInput.rolls == 2) return 3;
        return 6;
    }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1040)
        { fearProfile.traits = [rpgExpandedTemplateTraits.configured('intrusive-replay',2,nil,['evacuation memories'])];
          fearContext.intrusiveReplayContent = 'The apparition evokes the remembered evacuation'; return nil; }
        if (code == 1041) { replayFearInput.initial = 10; return nil; }
        if (code == 1042) { replayFearInput.initial = 9; return nil; }
        if (code == 1043) { fearProfile.traits = fearProfile.traits + [replayFearVoice]; return nil; }
        if (code == 1044) { fearContext.intrusiveReplayContent = nil; return nil; }
        if (code == 1045)
        { fearProfile.willAdjustment = -8; replayFearInput.low = true; ownedFearEvent.lowScoreDecision = replayFearDecision; return nil; }
        if (code == 1046) { replayFearDecision.replayStress = 'none'; return nil; }
        if (code == 1047) { replayFearDecision.replayStress = nil; return nil; }
        if (code == 1048 || code == 1049)
        { ownedFearEvent.resolve(); if (code == 1049) throw new RpgError(); return nil; }
        if (code == 1050)
        {
            event('test.replay-fear'); eventValue(fearProfile.fearEvents.length());
            eventValue(fearProfile.intrusiveReplayOccurrences.length()); eventValue(fearProfile.phantomVoiceOccurrences.length());
            eventValue(fearProfile.intrusiveReplaySeverity()); eventValue(rpgRandom.draws);
            eventValue(ownedFearEvent.result == nil || ownedFearEvent.result.check == nil ? nil : ownedFearEvent.result.check.roll);
            return nil;
        }
        return inherited(context);
    }
;
