#include "expanded-fear-mental.t"
attentionTrait: RpgExpandedShortAttention approved = true;
attentionContext: RpgLiteContext scoreFor(profile) { return 12; };
attentionTask: RpgExpandedAttentionTask id = 'decipher' profile = fearProfile trait = attentionTrait trigger = fearRoom
    taskContext = attentionContext occasion = 'distraction' evidence = 'A sudden noise interrupts deciphering' stressRelation = 'unrelated';
attentionInput: object controlRoll = 13;
modify rpgRandom roll() { self.draws += 3; return self.draws == 3 ? attentionInput.controlRoll : 7; };
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1200) { fearProfile.traits = [attentionTrait]; return nil; }
        if (code == 1201 || code == 1202) { attentionTask.resolve(); if (code == 1202) throw new RpgError(); return nil; }
        if (code == 1203) { attentionInput.controlRoll = 3; return nil; }
        if (code == 1204)
        {
            event('test.attention-task'); eventValue(fearProfile.selfControlTriggers.length());
            eventValue(attentionTask.taskCheck == nil ? nil : attentionTask.taskCheck.status);
            eventValue(attentionTask.taskCheck == nil ? nil : attentionTask.taskCheck.achieved);
            eventValue(attentionTask.taskCheck == nil ? nil : attentionTask.taskCheck.roll);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1205) { attentionTask.modifier = 1; attentionTask.assess(); return nil; }
        if (code == 1206) { attentionTask.taskCheck.achieved = !attentionTask.taskCheck.achieved; attentionTask.assess(); return nil; }
        if (code == 1207) { attentionTask.assess(); return nil; }
        if (code == 1220) { attentionContext.modifier = -10; return nil; }
        return inherited(context);
    }
;
