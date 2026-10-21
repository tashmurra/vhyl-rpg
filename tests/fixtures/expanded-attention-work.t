#include "expanded-attention-task.t"
attentionWorkSubject: object;
attentionWork: RpgExpandedAttentionWork id = 'cipher' profile = fearProfile subject = attentionWorkSubject requiredSteps = 2
    approved = true evidence = 'Two sections of a cipher must be completed';
attentionWorkFirst: RpgExpandedAttentionWorkStep id = 'first-section' work = attentionWork seconds = 60 money = 2 briefUndistracted = true
    approved = true evidence = 'A brief familiar transcription with no distraction';
attentionWorkSecond: RpgExpandedAttentionWorkStep id = 'second-section' work = attentionWork seconds = 120 money = 3 control = attentionWorkControl
    approved = true evidence = 'The second section is interrupted by a loud noise';
attentionWorkThird: RpgExpandedAttentionWorkStep id = 'extra-section' work = attentionWork seconds = 60 money = 2 briefUndistracted = true
    approved = true evidence = 'Cannot extend a terminal task';
attentionWorkControl: RpgExpandedAttentionWorkControl id = 'cipher-distraction' profile = fearProfile trait = attentionTrait trigger = attentionWorkSecond
    step = attentionWorkSecond occasion = 'distraction' evidence = 'A noise interrupts the second section' stressRelation = 'unrelated';
modify rpgRandom
    roll() { self.draws += 3; return attentionInput.controlRoll; }
    die() { self.draws += 1; return 2; }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1270) { fearProfile.traits = [attentionTrait]; fearProfile.money = 100; attentionWork.begin(); return nil; }
        if (code == 1271) { attentionWorkFirst.apply(); return nil; }
        if (code == 1272 || code == 1273)
        { attentionWorkSecond.apply(); if (code == 1273) throw new RpgError(); return nil; }
        if (code == 1274)
        {
            event('test.attention-work'); eventValue(attentionWork.state); eventValue(attentionWork.steps.length());
            eventValue(attentionWork.completedSteps); eventValue(attentionWork.committedSeconds); eventValue(attentionWork.committedMoney);
            eventValue(fearProfile.money); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1275) { attentionWorkThird.apply(); return nil; }
        if (code == 1276) { attentionWorkSecond.money += 1; attentionWork.validateState(); return nil; }
        if (code == 1277) { attentionWorkSecond.assess(); return nil; }
        if (code == 1278) { attentionWorkSecond.settle(true,nil); return nil; }
        if (code == 1279) { attentionTrait.mitigated = true; return nil; }
        return inherited(context);
    }
;
