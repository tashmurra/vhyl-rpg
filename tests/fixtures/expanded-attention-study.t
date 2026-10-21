#include "expanded-attention-task.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-development.t>
attentionSubject: RpgExpandedSkill id = 'decipher-test' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
attentionTraining: RpgTraining skill = attentionSubject points = 2;
attentionStudy: RpgExpandedStudy profile = fearProfile training = attentionTraining permitted = true credit = 2879900;
attentionSession: RpgExpandedAttentionStudy id = 'study-distraction' profile = fearProfile trait = attentionTrait trigger = attentionStudy
    study = attentionStudy seconds = 600 occasion = 'extended-focus' evidence = 'The ten-minute study task needs sustained focus' stressRelation = 'unrelated';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1210)
        { fearProfile.traits = [attentionTrait]; fearProfile.skills = [attentionTraining]; fearProfile.developmentOpen = true; return nil; }
        if (code == 1211 || code == 1212)
        { attentionSession.resolve(); if (code == 1212) throw new RpgError(); return nil; }
        if (code == 1213)
        {
            event('test.attention-study'); eventValue(fearProfile.selfControlTriggers.length()); eventValue(attentionTraining.points);
            eventValue(attentionStudy.credit); eventValue(attentionStudy.awarded); eventValue(rpgLedger.seconds);
            eventValue(fearProfile.studyUsed[2]); eventValue(rpgRandom.draws);
            eventValue(attentionSession.studyResult == nil ? nil : attentionSession.studyResult.reason); return nil;
        }
        if (code == 1214)
        { event('test.attention-direct'); eventValue(attentionStudy.advance(600).reason); return nil; }
        if (code == 1215) { attentionSession.assess(); return nil; }
        if (code == 1216) { attentionSession.studyResult.points += 1; attentionSession.assess(); return nil; }
        if (code == 1217) { attentionTrait.mitigated = true; return nil; }
        if (code == 1218) { attentionStudy.advanceAttention(attentionSession); return nil; }
        if (code == 1219) { attentionStudy.permitted = nil; return nil; }
        if (code == 1221)
        { attentionStudy.attentionSituation = 'brief-undistracted'; attentionStudy.attentionEvidence = 'A short familiar review, with no distraction'; return nil; }
        return inherited(context);
    }
;
