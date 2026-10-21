#include "expanded-paleontology-skill.t"
#include <vhyl-rpg-expanded-exploration.t>
paleontologySpecimen: object;
modify crossPhysician skills = [fossilTraining];
modify fossilContext task = 'habitat';
paleontologyAssessment: RpgExpandedPaleontologyAssessment id = 'fossil-habitat' profile = crossPhysician context = fossilContext
    specimen = paleontologySpecimen accessible = true approved = true evidence = 'The observed specimen supports this habitat finding'
    finding = 'This organism lived in shallow coastal water';
paleontologyDuplicate: RpgExpandedPaleontologyAssessment id = 'second-fossil-habitat' profile = crossPhysician context = fossilContext
    specimen = paleontologySpecimen accessible = true approved = true evidence = 'Same specimen and task'
    finding = 'This organism lived in shallow coastal water';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 21900 || code == 21901)
        { local value = paleontologyAssessment.resolve(); event('test.paleontology-finding'); eventValue(value.status); eventValue(value.finding);
          if (code == 21901) throw new RpgError(); return nil; }
        if (code == 21902)
        { event('test.paleontology-history'); eventValue(crossPhysician.paleontologyAssessments.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 21903) { rpgRandom.medicalRoll = 18; return nil; }
        if (code == 21904)
        { local value = paleontologyAssessment.assess(); event('test.paleontology-preview'); eventValue(value.status); eventValue(value.score); eventValue(value.finding); eventValue(value.reason); return nil; }
        if (code == 21905)
        {
            fossilContext.laboratory = true;
            try { paleontologyAssessment.resolve(); }
            catch (RpgExpandedError error) { event('test.paleontology-binding'); eventValue(error.reason); }
            return nil;
        }
        if (code == 21906) { paleontologyAssessment.accessible = nil; return nil; }
        if (code == 21907) { paleontologyAssessment.finding = nil; return nil; }
        if (code == 21908) { fossilSkill.specialty = 'microscopic'; return nil; }
        if (code == 21909)
        {
            try { paleontologyDuplicate.resolve(); }
            catch (RpgExpandedError error) { event('test.paleontology-binding'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
