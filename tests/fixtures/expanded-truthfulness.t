#include "expanded-self-control.t"
truthTrait: RpgExpandedTruthfulness approved = true selfControlRating = 12;
truthFastTalk: RpgLiteSkill id = 'fast-talk' attribute = rpgIQ difficulty = 1;
truthActing: RpgLiteSkill id = 'acting' attribute = rpgIQ difficulty = 1;
truthFastTraining: RpgTraining skill = truthFastTalk points = 2;
truthActTraining: RpgTraining skill = truthActing points = 2;
modify bleedProfile traits = [truthTrait] skills = [truthFastTraining,truthActTraining];
truthTrigger: RpgExpandedTruthfulnessTrigger id = 'relevant-question' profile = bleedProfile trait = truthTrait
    trigger = 'original-disclosure-opportunity' truth = 'original-relevant-truth' falsehood = 'original-proposed-falsehood'
    evidence = 'Only this uncomfortable fact is relevant to this authored occurrence';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 600) { truthTrigger.assess(); return nil; }
        if (code == 601 || code == 602)
        { truthTrigger.resolve(); if (code == 602) throw new RpgError(); return nil; }
        if (code == 603)
        {
            event('test.truthfulness'); eventValue(bleedProfile.selfControlTriggers.length());
            eventValue(truthTrigger.check == nil ? nil : truthTrigger.check.score);
            eventValue(truthTrigger.result == nil ? nil : truthTrigger.result.communicationKind);
            eventValue(truthTrigger.result == nil ? nil : truthTrigger.result.statement);
            eventValue(truthTrigger.active ? 1 : 0); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 604) { truthTrigger.mode = 'falsehood'; return nil; }
        if (code == 605) { truthTrigger.failureChoice = 'obvious-lie'; return nil; }
        if (code == 606) { truthTrait.selfControlRating = 15; return nil; }
        if (code == 607) { truthTrigger.giveIn = true; return nil; }
        if (code == 608) { truthTrigger.truth = nil; return nil; }
        if (code == 609)
        {
            local check = new RpgLiteContext(); check.skill = truthFastTalk;
            event('test.truthfulness-skills'); eventValue(rpgLiteScore(bleedProfile,check));
            check.skill = truthActing; eventValue(rpgLiteScore(bleedProfile,check));
            check.deceptive = true; eventValue(rpgLiteScore(bleedProfile,check)); return nil;
        }
        return inherited(context);
    }
;
