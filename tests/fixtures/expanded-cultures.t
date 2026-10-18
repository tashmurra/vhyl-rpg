#include "expanded-makeup.t"
homeCulture: RpgExpandedCulture id = 'river-towns' approved = true evidence = 'Shared river-town customs';
nearCulture: RpgExpandedCulture id = 'upland-towns' approved = true evidence = 'Shared upland customs';
farCulture: RpgExpandedCulture id = 'reef-communities' approved = true evidence = 'Shared reef community customs';
nearFamiliarity: RpgExpandedCulturalFamiliarity id = 'culture-upland-towns' culture = nearCulture
    approved = true evidence = 'Related culture learned during upbringing';
farFamiliarity: RpgExpandedCulturalFamiliarity id = 'culture-reef-communities' culture = farCulture alien = true
    approved = true evidence = 'Alien culture learned during an exchange';
modify crossPhysician nativeCulture = homeCulture traits = [nearFamiliarity];
gestureCatalogue: RpgExpandedGestureSkill;
gestureTask: RpgExpandedGestureContext skill = gestureCatalogue culture = homeCulture
    cultureEvidence = 'This hand signal uses the recipient community vocabulary'
    simpleIdea = true idea = 'Wait beside the doorway' observed = true;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 26200)
        { event('test.culture'); eventValue(rpgLiteScore(crossPhysician,gestureTask));
          eventValue(nearFamiliarity.creationCost()); eventValue(farFamiliarity.creationCost());
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 26201) { gestureTask.culture = nearCulture; return nil; }
        if (code == 26202) { gestureTask.culture = farCulture; return nil; }
        if (code == 26203) { crossPhysician.traits = [nearFamiliarity,farFamiliarity]; return nil; }
        if (code == 26204) { nearFamiliarity.mitigated = true; return nil; }
        if (code == 26205) { gestureTask.simpleIdea = nil; return nil; }
        if (code == 26206) { gestureTask.observed = nil; return nil; }
        if (code == 26207) { gestureTask.operation = 'understand'; return nil; }
        if (code == 26208) { gestureTask.cultureEvidence = nil; return nil; }
        if (code == 26209)
        { crossPhysician.nativeCulture = nearCulture; crossPhysician.validateCultures(); return nil; }
        if (code == 26210)
        { crossPhysician.traits = [nearFamiliarity,nearFamiliarity]; crossPhysician.validateCultures(); return nil; }
        return inherited(context);
    }
;
