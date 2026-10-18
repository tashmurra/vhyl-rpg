#include "expanded-biology-skill.t"
biologySubfieldInput: object skill = nil;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 20100 || code == 20101)
        {
            local skill = rpgExpandedBiologySubfield(biologyCatalogue,'biology-botany','botany',true,'Botany is a coherent scientific field at this technology');
            biologySubfieldInput.skill = skill; local training = new RpgTraining(); training.skill = skill; training.points = 4;
            crossPhysician.skills = [training];
            if (code == 20101) throw new RpgError(); return nil;
        }
        if (code == 20102)
        {
            event('test.biology-subfield');
            eventValue(biologySubfieldInput.skill == nil ? nil : crossPhysician.skillScore(biologySubfieldInput.skill));
            eventValue(crossPhysician.skillScore(biologyCatalogue)); eventValue(crossPhysician.skillScore(alienBiology));
            eventValue(crossPhysician.skills.length()); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 20103 || code == 20104 || code == 20105)
        {
            if (code == 20105) biologyCatalogue.specialty = 'unknown';
            try { rpgExpandedBiologySubfield(biologyCatalogue,'biology-botany','botany',code != 20103,code == 20104 ? nil : 'Appropriate for this technology'); }
            catch (RpgExpandedError error) { event('test.biology-subfield-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
