#include "expanded-paleontology-equipment.t"
fossilLabType: object;
fossilFamiliarity: RpgExpandedFamiliarity owner = crossPhysician skill = fossilSkill equipmentType = fossilLabType available = true;
modify crossPhysician familiarities = [fossilFamiliarity];
modify fossilContext familiarity = fossilFamiliarity;
fossilSecondSpecimen: object;
fossilSecondStudy: RpgExpandedPaleontologyAssessment id = 'second-age' profile = crossPhysician context = fossilContext
    specimen = fossilSecondSpecimen accessible = true approved = true evidence = 'Independent specimen with dating evidence'
    finding = 'The second fossil is approximately one million years old';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 22300 || code == 22301)
        { local value = code == 22300 ? paleontologyAssessment.resolve() : fossilSecondStudy.assess();
          event('test.fossil-familiarity'); eventValue(value.status); eventValue(value.score); eventValue(value.familiarityModifier); return nil; }
        if (code == 22302) { fossilFamiliarity.advance(28800); return nil; }
        if (code == 22303 || code == 22304 || code == 22305)
        {
            if (code == 22303) fossilFamiliarity.equipmentType = fossilSecondSpecimen;
            else if (code == 22304) paleontologyAssessment.result.familiarityModifier = 0;
            else paleontologyAssessment.result.score += 1;
            try { paleontologyAssessment.assess(); }
            catch (RpgExpandedError error) { event('test.fossil-familiarity-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
