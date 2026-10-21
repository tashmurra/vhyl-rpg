#include "expanded-physiology-skill.t"
physicianCatalogue: RpgExpandedPhysicianSkill techLevel = 8;
firstAidCatalogue: RpgExpandedFirstAidSkill techLevel = 8;
medicalSource: RpgExpandedSkill id = 'veterinary' attribute = rpgIQ difficulty = 2 techLevel = 8;
medicalSourceTraining: RpgTraining skill = medicalSource points = 20;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 19700)
        { event('test.medical-scores'); eventValue(crossPhysician.skillScore(physicianCatalogue)); eventValue(crossPhysician.skillScore(firstAidCatalogue)); eventValue(rpgRandom.draws); return nil; }
        if (code == 19701) { crossPhysician.skills = [medicalSourceTraining]; return nil; }
        if (code == 19702) { medicalSource.id = 'first-aid'; medicalSource.difficulty = 0; medicalSourceTraining.points = 40; return nil; }
        if (code == 19703) { medicalSource.id = 'physician'; return nil; }
        if (code == 19704) { medicalSource.id = 'traditional-treatment'; medicalSource.attribute = rpgPerception; medicalSource.techLevel = nil; return nil; }
        if (code == 19705) { medicalSource.techLevel = 7; return nil; }
        if (code == 19706 || code == 19707)
        {
            physicianCatalogue.techLevel = 4;
            if (code == 19707) { physicianCatalogue.earlyMedicineApproved = true; physicianCatalogue.earlyMedicineEvidence = 'Scientific medicine exists in this setting'; }
            try { physicianCatalogue.validateDefinition(); event('test.medical-definition'); eventValue('ready'); }
            catch (RpgExpandedError error) { event('test.medical-definition'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
