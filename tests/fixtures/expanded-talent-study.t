#include "expanded-learning-bar.t"
studyTalent: RpgLiteTrait id = 'artificer' points = 10 level = 2;
studyTalentSkill: RpgExpandedSkill id = 'mechanic' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
studyTalentTraining: RpgExpandedTraining skill = studyTalentSkill points = 1;
studyTalentTrack: RpgExpandedStudy profile = bleedProfile training = studyTalentTraining permitted = true;
modify bleedProfile traits = [studyTalent] skills = [studyTalentTraining];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 6800 || code == 6801)
        {
            local value = code == 6800 ? studyTalentTrack.assess(3600) : studyTalentTrack.advance(3600);
            event('test.talent-study'); eventValue(value.status); eventValue(value.points); return nil;
        }
        if (code == 6802)
        {
            event('test.talent-study-state'); eventValue(studyTalentTrack.credit); eventValue(studyTalentTrack.awarded);
            eventValue(studyTalentTraining.points); eventValue(studyTalentTrack.learningThreshold());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); eventValue(bleedProfile.unspentPoints); return nil;
        }
        if (code == 6803)
        { studyTalentTrack.creditThreshold = studyTalentTrack.learningThreshold(); studyTalentTrack.credit = studyTalentTrack.creditThreshold - 7200; return nil; }
        if (code == 6804) { studyTalent.level = 4; return nil; }
        if (code == 6805) { studyTalent.mitigated = true; return nil; }
        if (code == 6806) { studyTalentSkill.id = 'unrelated'; return nil; }
        if (code == 6807)
        {
            event('test.talent-study-error');
            try { studyTalentTrack.advance(3600); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(studyTalentTrack.credit); eventValue(rpgLedger.seconds); eventValue(studyTalentTraining.points); return nil;
        }
        if (code >= 6810 && code <= 6813) { studyTalent.level = code - 6809; return nil; }
        if (code == 6814) { studyTalentSkill.id = 'smith'; return nil; }
        if (code == 6815) { studyTalentSkill.id = 'fishing'; bleedProfile.traits = [rpgLiteMakeTrait('outdoorsman',2,nil)]; return nil; }
        if (code == 6816) { studyTalentSkill.id = 'detect-lies'; bleedProfile.traits = [rpgLiteMakeTrait('smooth-operator',2,nil)]; return nil; }
        return inherited(context);
    }
;
