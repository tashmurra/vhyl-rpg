#include "expanded-physician-physiology.t"
cataloguePhysiology: RpgExpandedPhysiologySkill techLevel = 8 specialty = 'river-folk';
otherPhysiology: RpgExpandedPhysiologySkill techLevel = 8 specialty = 'hill-folk';
otherPhysiologyTraining: RpgTraining skill = otherPhysiology points = 20;
clinicalDefault: RpgExpandedSkill id = 'diagnosis' attribute = rpgIQ difficulty = 2 techLevel = 8;
clinicalDefaultTraining: RpgTraining skill = clinicalDefault points = 20;
physiologyRelation: RpgExpandedPhysiologyDefault source = otherPhysiology penalty = -2 approved = true evidence = 'Author established closely related anatomy';
modify crossPhysician skills = [];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 19600)
        { event('test.physiology-skill'); eventValue(crossPhysician.skillScore(cataloguePhysiology)); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 19601 || code == 19602 || code == 19603)
        { clinicalDefault.id = code == 19601 ? 'diagnosis' : code == 19602 ? 'physician' : 'surgery'; crossPhysician.skills = [clinicalDefaultTraining]; return nil; }
        if (code == 19604) { clinicalDefault.techLevel = 7; return nil; }
        if (code == 19605) { crossPhysician.skills = [otherPhysiologyTraining]; return nil; }
        if (code == 19606) { cataloguePhysiology.speciesDefaults = [physiologyRelation]; return nil; }
        if (code == 19607) { otherPhysiologyTraining.points = 0; return nil; }
        if (code == 19608 || code == 19609 || code == 19610)
        {
            cataloguePhysiology.speciesDefaults = [physiologyRelation];
            if (code == 19608) physiologyRelation.approved = nil;
            if (code == 19609) cataloguePhysiology.specialty = nil;
            if (code == 19610) cataloguePhysiology.speciesDefaults = [physiologyRelation,physiologyRelation];
            try { cataloguePhysiology.validateDefinition(); }
            catch (RpgExpandedError error) { event('test.physiology-skill-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
