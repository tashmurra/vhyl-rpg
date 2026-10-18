#include "expanded-health-transactions.t"
#include <vhyl-rpg-expanded-skills.t>
crossMedicalSkill: RpgExpandedSkill id = 'physician' attribute = rpgIQ difficulty = 2 techLevel = 8;
crossMedicalTraining: RpgTraining skill = crossMedicalSkill points = 4;
crossMedicalKnowledge: RpgExpandedSkill id = 'physiology' attribute = rpgIQ difficulty = 2 techLevel = 8 specialty = 'river-folk';
crossMedicalKnowledgeTraining: RpgTraining skill = crossMedicalKnowledge points = 4;
crossPhysician: RpgExpandedProfile rules = healthRules iq = 12 techLevel = 8 skills = [crossMedicalTraining,crossMedicalKnowledgeTraining];
physicianKnowledge: RpgExpandedPhysiologyCheck id = 'physician-knowledge' profile = crossPhysician subject = physicianPatient operation = physicianCheck
    species = 'river-folk' skill = crossMedicalKnowledge approved = true evidence = 'Relevant patient specialty';
modify medicalClinic physician = crossPhysician skill = crossMedicalSkill;
modify physicianCheck physiology = 'similar' speciesModifier = -3 subjectSpecies = 'river-folk';
modify rpgRandom
    medicalRoll = 3
    roll() { self.draws += 3; return self.medicalRoll; }
;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 19500) { medicalClinic.admit(physicianPatient); rpgSpendTime(86400); return nil; }
        if (code == 19501 || code == 19502)
        { physicianCheck.physiologyCheck = physicianKnowledge; rpgRandom.medicalRoll = code == 19501 ? 3 : 18; physicianKnowledge.apply(); return nil; }
        if (code == 19503)
        {
            local value = physicianCheck.assess(); event('test.physician-physiology'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.context == nil ? nil : rpgLiteScore(crossPhysician,value.context)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 19504) { physicianCheck.physiology = 'machine'; return nil; }
        if (code == 19507) { physicianCheck.physiologyCheck = physicianKnowledge; return nil; }
        if (code == 19505 || code == 19506)
        {
            rpgRandom.medicalRoll = 3; physicianCheck.apply();
            if (code == 19506) throw new RpgError();
            return nil;
        }
        if (code == 19508)
        {
            physicianCheck.subjectSpecies = 'other-species';
            try { physicianCheck.assess(); }
            catch (RpgExpandedError error) { event('test.physician-physiology-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
