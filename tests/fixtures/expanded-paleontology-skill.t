#include "expanded-anthropology-skill.t"
fossilSkill: RpgExpandedPaleontologySkill techLevel = 8 specialty = 'human-origins';
fossilOther: RpgExpandedPaleontologySkill techLevel = 8 specialty = 'plants';
fossilOtherTraining: RpgTraining skill = fossilOther points = 24;
fossilTraining: RpgTraining skill = fossilSkill points = 24;
fossilBiology: RpgExpandedBiologySkill techLevel = 8 specialty = 'habitable';
fossilBiologyTraining: RpgTraining skill = fossilBiology points = 24;
fossilContext: RpgExpandedPaleontologyContext skill = fossilSkill approved = true evidence = 'The fossil evidence supports this kind of study';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 21800)
        { event('test.fossil-score'); eventValue(fossilContext.unavailableReason(crossPhysician)); eventValue(rpgLiteScore(crossPhysician,fossilContext)); eventValue(rpgRandom.draws); return nil; }
        if (code == 21801) { crossPhysician.skills = [fossilBiologyTraining]; return nil; }
        if (code == 21802) { crossPhysician.skills = [anthropologyForeignTraining]; return nil; }
        if (code == 21803) { crossPhysician.skills = [fossilOtherTraining]; return nil; }
        if (code == 21804) { crossPhysician.skills = [fossilTraining]; fossilSkill.specialty = 'microscopic'; return nil; }
        if (code == 21805) { fossilContext.laboratory = true; return nil; }
        if (code == 21806) { fossilContext.task = 'age'; fossilContext.equipmentModifier = 2; return nil; }
        if (code == 21807) { fossilBiology.techLevel = 7; return nil; }
        if (code == 21808) { fossilOtherTraining.points = 0; return nil; }
        if (code == 21809) { fossilSkill.specialty = 'animals'; return nil; }
        if (code >= 21810 && code <= 21812)
        {
            if (code == 21810) fossilContext.approved = nil;
            if (code == 21811) fossilContext.equipmentModifier = 2;
            if (code == 21812) fossilSkill.specialty = 'unknown';
            try { fossilContext.validatePaleontology(); }
            catch (RpgExpandedError error) { event('test.fossil-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
