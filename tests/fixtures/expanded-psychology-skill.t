#include "expanded-physiology-skill.t"
psychologyGeneral: RpgExpandedPsychologySkill specialty = 'river-folk';
psychologyApplied: RpgExpandedPsychologySkill specialty = 'river-folk' discipline = 'applied' splitApproved = true splitEvidence = 'Campaign uses separate scientific and applied training';
psychologyExperimental: RpgExpandedPsychologySkill specialty = 'river-folk' discipline = 'experimental' splitApproved = true splitEvidence = 'Campaign uses separate scientific and applied training';
psychologyTraining: RpgTraining skill = psychologyExperimental points = 24;
psychologyLie: RpgExpandedLieDetectionSkill;
psychologyForeign: RpgExpandedPsychologySkill specialty = 'hill-folk' discipline = 'applied' splitApproved = true splitEvidence = 'Campaign uses split training';
psychologyRelation: RpgExpandedPsychologyDefault source = psychologyForeign penalty = -3 approved = true evidence = 'Author established this species relationship';
psychologySociology: RpgExpandedSkill id = 'sociology' attribute = rpgIQ difficulty = 2 specialty = 'river-folk';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 20800)
        {
            event('test.psychology-scores'); eventValue(crossPhysician.skillScore(psychologyApplied));
            eventValue(crossPhysician.skillScore(psychologyExperimental)); eventValue(crossPhysician.skillScore(psychologyLie));
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 20801) { crossPhysician.skills = [psychologyTraining]; return nil; }
        if (code == 20802) { psychologyTraining.skill = psychologyApplied; return nil; }
        if (code == 20804) { psychologyTraining.skill = psychologyForeign; psychologyApplied.speciesDefaults = [psychologyRelation]; return nil; }
        if (code == 20805) { psychologyTraining.skill = psychologySociology; return nil; }
        if (code == 20803)
        {
            psychologyApplied.splitApproved = nil;
            try { psychologyApplied.validateDefinition(); }
            catch (RpgExpandedError error) { event('test.psychology-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
