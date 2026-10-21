#include "expanded-ancestry-omissions.t"
ancestryFlightSkill: RpgExpandedSkill id = 'flight' attribute = rpgHT difficulty = 1 defaultPenalty = -5;
ancestryStealthSkill: RpgExpandedSkill id = 'stealth' attribute = rpgDX difficulty = 1 defaultPenalty = -5;
ancestryLearned: RpgExpandedAncestryTemplate
    id = 'winged-ancestry' approved = true evidence = 'Approved innate training' nonhuman = true
    dxChange = 4 htChange = -1 skillRows = [[ancestryFlightSkill,2],[ancestryStealthSkill,4]]
;
ancestryLearnedDuplicate: RpgExpandedAncestryTemplate
    id = 'other-training' approved = true evidence = 'Overlapping ancestry training'
    skillRows = [[ancestryFlightSkill,2]]
;
ancestryTrainedPersonal: RpgExpandedTemplate
    dx = 12 ht = 12 pointBudget = 1000 skillRows = [[ancestryFlightSkill,2]]
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 6500 || code == 6501)
        {
            ancestryState.profile = rpgExpandedCreateAncestryCharacter(code == 6500 ? ancestryPlain : ancestryTrainedPersonal,
                [ancestryLearned],bleedRules);
            ancestryState.profile.unspentPoints = 100; ancestryState.profile.developmentOpen = true; return nil;
        }
        if (code == 6502)
        {
            event('test.ancestry-training-learn');
            eventValue(rpgLiteLearn(ancestryState.profile,ancestryFlightSkill,4,nil) ? 1 : 0);
            eventValue(ancestryState.profile.unspentPoints); return nil;
        }
        if (code == 6503)
        {
            local p = ancestryState.profile; event('test.ancestry-training');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(rpgExpandedTrainingFor(p,ancestryFlightSkill).points);
            eventValue(rpgExpandedTrainingFor(p,ancestryStealthSkill).points);
            eventValue(p.skillScore(ancestryFlightSkill)); eventValue(p.skillScore(ancestryStealthSkill));
            eventValue(p.ancestryScores.trainings[1][3]); eventValue(p.skills.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 6504) { rpgExpandedTrainingFor(ancestryState.profile,ancestryFlightSkill).points = 1; return nil; }
        if (code == 6505) { ancestryState.profile.skills = []; return nil; }
        if (code == 6506) { bleedProfile.skills = [ancestryState.profile.skills[1]]; return nil; }
        if (code == 6507) { ancestryState.profile.skills[1].defaultFrom = ancestryStealthSkill; return nil; }
        if (code == 6508)
        {
            event('test.ancestry-training-error');
            try { rpgExpandedCreateAncestryCharacter(ancestryPlain,[ancestryLearned,ancestryLearnedDuplicate],bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
