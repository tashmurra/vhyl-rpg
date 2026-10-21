#include "expanded-paleontology-assessment.t"
packingCatalogue: RpgExpandedPackingSkill;
packingTraining: RpgTraining skill = packingCatalogue points = 12;
packingHandling: RpgExpandedAnimalHandlingSkill specialty = 'equines';
packingHandlingTraining: RpgTraining skill = packingHandling points = 24;
packingCaravan: RpgExpandedPackTrain members = [[crossPhysician,packingCatalogue]] approved = true evidence = 'This handler participates in the caravan';
modify crossPhysician skills = [];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 22400)
        { local value = packingCaravan.assess(); event('test.packing'); eventValue(crossPhysician.skillScore(packingCatalogue));
          eventValue(value.speedPercent); eventValue(value.master == crossPhysician); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 22401) { crossPhysician.skills = [packingTraining]; return nil; }
        if (code == 22402) { packingTraining.points = 8; return nil; }
        if (code == 22403) { crossPhysician.skills = [packingHandlingTraining]; return nil; }
        if (code == 22404) { packingHandling.specialty = 'hounds'; return nil; }
        if (code == 22405) { packingHandlingTraining.points = 0; return nil; }
        if (code == 22406) { crossPhysician.unconscious = true; return nil; }
        if (code == 22407) { packingCaravan.members = []; return nil; }
        if (code == 22408)
        {
            packingCaravan.members = [[crossPhysician,packingCatalogue],[crossPhysician,packingCatalogue]];
            try { packingCaravan.assess(); }
            catch (RpgExpandedError error) { event('test.packing-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
