#include "expanded-fear-mental.t"
replayStressor: object;
replayInput: object roll = 6;
replaySkill: RpgLiteSkill;
replayContext: RpgLiteContext skill = replaySkill;
replayOccurrence: RpgExpandedIntrusiveReplayOccurrence id = 'alarm-replay' profile = fearProfile stressor = replayStressor
    approved = true evidence = 'A sudden alarm evokes a stressful memory'
    content = 'The character experiences the remembered evacuation';
modify rpgRandom
    roll() { self.draws += 3; return replayInput.roll; }
    die() { self.draws += 1; return 2; }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code >= 1010 && code <= 1012)
        { fearProfile.traits = [rpgExpandedTemplateTraits.configured('intrusive-replay',code-1009,nil,['evacuation memories'])]; return nil; }
        if (code == 1013) { replayInput.roll = 7; return nil; }
        if (code == 1014 || code == 1015)
        { replayOccurrence.resolve(); if (code == 1015) throw new RpgError(); return nil; }
        if (code == 1016)
        {
            event('test.replay'); eventValue(fearProfile.intrusiveReplayOccurrences.length());
            eventValue(replayOccurrence.result == nil ? 0 : replayOccurrence.result.duration);
            eventValue(fearProfile.intrusiveReplaySeverity());
            eventValue(fearProfile.healthAttributeModifier(replayContext));
            eventValue(fearProfile.healthCheckReason(replayContext));
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1017) { rpgSpendTime(replayOccurrence.expiresAt-rpgLedger.seconds); return nil; }
        if (code == 1018) { replayOccurrence.content = 'Changed memory'; replayOccurrence.assess(); return nil; }
        if (code == 1019)
        {
            event('test.replay-prices');
            foreach (local level in [1,2,3])
            { local trait = rpgExpandedTemplateTraits.configured('intrusive-replay',level,nil,['evacuation memories']);
              local copy = rpgExpandedTemplateTraits.copy(trait); eventValue(copy.creationCost());
              eventValue(copy != trait ? 1 : 0); eventValue(copy.replayType); }
            return nil;
        }
        if (code == 1110)
        { event('test.replay-type'); eventValue(replayOccurrence.replayType);
          eventValue(replayOccurrence.result == nil ? nil : replayOccurrence.result.replayType); return nil; }
        if (code == 1111) { replayOccurrence.replayType = 'Changed type'; replayOccurrence.assess(); return nil; }
        if (code == 1112) { replayOccurrence.result.replayType = 'Changed result type'; replayOccurrence.assess(); return nil; }
        return inherited(context);
    }
;
