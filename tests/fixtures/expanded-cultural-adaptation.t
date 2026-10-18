#include "expanded-culture-templates.t"
riverSpecies: object;
reefSpecies: object;
cultureWorld: object;
otherCultureWorld: object;
modify homeCulture species = [riverSpecies] world = cultureWorld;
modify nearCulture species = [riverSpecies] world = cultureWorld;
modify farCulture species = [reefSpecies] world = cultureWorld;
modify healthRules cinematicCulturalAdaptation = true;
cultureAdaptation: RpgExpandedCulturalAdaptation approved = true evidence = 'Campaign permits broad cultural understanding';
modify crossPhysician culturalSpecies = riverSpecies traits = [cultureAdaptation];
adaptationPackage: RpgExpandedTemplate nativeCulture = homeCulture culturalSpecies = riverSpecies
    traitRows = [['cultural-adaptation',1,nil,nil,['own-species',nil,'Campaign permits broad cultural understanding']]];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 26400)
        { event('test.cultural-adaptation'); eventValue(rpgLiteScore(crossPhysician,gestureTask));
          eventValue(cultureAdaptation.creationCost()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 26401) { gestureTask.culture = nearCulture; return nil; }
        if (code == 26402) { gestureTask.culture = farCulture; return nil; }
        if (code == 26403) { cultureAdaptation.mitigated = true; return nil; }
        if (code == 26404) { cultureAdaptation.active = nil; return nil; }
        if (code == 26405) { cultureAdaptation.coverage = 'world'; cultureAdaptation.world = cultureWorld; return nil; }
        if (code == 26406) { farCulture.world = otherCultureWorld; return nil; }
        if (code == 26407)
        { healthRules.cinematicCulturalAdaptation = nil; crossPhysician.culturalAdaptationTrait(); return nil; }
        if (code == 26408)
        { crossPhysician.traits = [cultureAdaptation,cultureAdaptation]; crossPhysician.culturalAdaptationTrait(); return nil; }
        if (code == 26409)
        { nearCulture.species = []; crossPhysician.culturalPenalty(nearCulture); return nil; }
        if (code == 26410)
        {
            local first = adaptationPackage.create(healthRules); local second = adaptationPackage.createSelected(healthRules,[]);
            first.traits[1].mitigated = true;
            event('test.adaptation-template'); eventValue(first.culturalPenalty(nearCulture));
            eventValue(second.culturalPenalty(nearCulture)); eventValue(second.traits[1].creationCost()); return nil;
        }
        return inherited(context);
    }
;
