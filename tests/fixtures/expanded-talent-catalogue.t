#include "expanded-talent-reaction.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 7200 && code <= 7206)
        {
            local ids = ['animal-aptitude','commercial-aptitude','artistic-aptitude','plant-aptitude',
                'medical-aptitude','numerical-aptitude','musical-aptitude'];
            local skills = ['riding','accounting','sewing','biology','surgery','physics','singing'];
            local talent = rpgExpandedMakeCatalogueTalent(ids[code-7199],2,true);
            bleedProfile.traits = [talent]; studyTalentSkill.id = skills[code-7199];
            talentReactionContext.talent = talent; return nil;
        }
        if (code == 7207)
        {
            local cost = 0; foreach (local trait in bleedProfile.traits) cost += trait.creationCost();
            event('test.talent-catalogue'); eventValue(cost);
            eventValue(bleedProfile.skillScore(studyTalentSkill));
            eventValue(bleedProfile.studyTimePercent(studyTalentSkill));
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7210)
        {
            bleedProfile.traits = [rpgExpandedMakeCatalogueTalent('animal-aptitude',4,true),
                rpgExpandedMakeCatalogueTalent('medical-aptitude',4,true)];
            studyTalentSkill.id = 'veterinary'; return nil;
        }
        if (code == 7211 || code == 7212)
        {
            studyTalentSkill.id = 'group-performance';
            studyTalentSkill.specialty = code == 7211 ? 'acting' : 'conducting'; return nil;
        }
        if (code == 7213)
        {
            event('test.talent-catalogue-error');
            try { rpgExpandedMakeCatalogueTalent('animal-aptitude',2,nil); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
