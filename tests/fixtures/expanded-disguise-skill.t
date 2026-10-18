#include "expanded-distinctive-features.t"
disguiseCatalogue: RpgExpandedDisguiseSkill techLevel = 8 specialty = distinctiveSpecies;
disguiseOtherSpecies: object;
disguiseOther: RpgExpandedDisguiseSkill techLevel = 8 specialty = disguiseOtherSpecies;
disguiseOtherTraining: RpgTraining skill = disguiseOther points = 24;
disguiseTraining: RpgTraining skill = disguiseCatalogue points = 4;
disguiseMakeup: RpgExpandedSkill id = 'makeup' techLevel = 8 attribute = rpgIQ difficulty = 0 defaultPenalty = -4;
disguiseMakeupTraining: RpgTraining skill = disguiseMakeup points = 8;
disguiseAssessment: RpgExpandedDisguiseContext skill = disguiseCatalogue approved = true evidence = 'Same-size disguise for the specified species';
modify crossPhysician skills = [];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 25400)
        { event('test.disguise-score'); eventValue(crossPhysician.skillScore(disguiseCatalogue));
          eventValue(rpgLiteScore(crossPhysician,disguiseAssessment)); eventValue(disguiseAssessment.unavailableReason(crossPhysician));
          eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 25401) { crossPhysician.skills = [disguiseTraining]; return nil; }
        if (code == 25402) { crossPhysician.skills = [disguiseOtherTraining];
            disguiseCatalogue.similarSpeciesDefaults = [[disguiseOther,-3,'Similar facial structure']]; return nil; }
        if (code == 25403) { disguiseAssessment.elasticSkin = true; disguiseAssessment.differentAppearancePenalty = -2; return nil; }
        if (code == 25404) { disguiseAssessment.sharedByCrowd = true; return nil; }
        if (code == 25405) { disguiseAssessment.sizeModifierDifference = 1; return nil; }
        if (code == 25407) { crossPhysician.skills = [disguiseMakeupTraining]; return nil; }
        if (code == 25406)
        {
            disguiseOther.specialty = 'animals';
            try { disguiseCatalogue.validateDefinition(); }
            catch (RpgExpandedError error) { event('test.disguise-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
