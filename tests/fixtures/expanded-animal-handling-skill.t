#include "expanded-veterinary-skill.t"
handlingSource: RpgExpandedAnimalHandlingSkill specialty = 'hounds';
handlingTarget: RpgExpandedAnimalHandlingSkill specialty = 'large-cats';
handlingTraining: RpgTraining skill = handlingSource points = 20;
handlingRelation: RpgExpandedAnimalHandlingDefault source = handlingSource relationship = 'same-order' approved = true
    evidence = 'Both categories belong to the same order in this setting';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 20700)
        { event('test.handling-score'); eventValue(crossPhysician.skillScore(handlingTarget)); eventValue(crossPhysician.skillScore(veterinaryCatalogue)); eventValue(rpgRandom.draws); return nil; }
        if (code == 20701) { crossPhysician.skills = [handlingTraining]; handlingTarget.relationships = [handlingRelation]; return nil; }
        if (code == 20702) { handlingRelation.relationship = 'different-order'; return nil; }
        if (code == 20703) { handlingRelation.relationship = 'distant'; return nil; }
        if (code == 20704) { handlingTraining.points = 0; return nil; }
        if (code == 20705)
        {
            handlingRelation.approved = nil;
            try { handlingTarget.validateDefinition(); }
            catch (RpgExpandedError error) { event('test.handling-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
