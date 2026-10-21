#include "expanded-cultures.t"
culturalLiteContext: RpgLiteContext skill = gestureCatalogue taskCulture = farCulture taskCultureEvidence = 'Signal vocabulary is cultural';
culturalExpandedContext: RpgExpandedSkillContext skill = gestureCatalogue taskCulture = farCulture taskCultureEvidence = 'Signal vocabulary is cultural';
modify makeupContextFixture taskCulture = farCulture taskCultureEvidence = 'The presentation depends on local cosmetic customs';
modify gestureTask culture = farCulture;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 26800)
        { event('test.cultural-scoring'); eventValue(rpgLiteScore(crossPhysician,culturalLiteContext));
          eventValue(rpgLiteScore(crossPhysician,culturalExpandedContext)); eventValue(rpgLiteScore(crossPhysician,gestureTask));
          eventValue(rpgLiteScore(crossPhysician,makeupContextFixture)); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 26801)
        { culturalLiteContext.modifier = 2; culturalExpandedContext.modifier = 2; gestureTask.modifier = 2; makeupContextFixture.modifier = 2; return nil; }
        if (code == 26802)
        { culturalLiteContext.taskCulture = nearCulture; culturalExpandedContext.taskCulture = nearCulture;
          gestureTask.culture = nearCulture; makeupContextFixture.taskCulture = nearCulture; return nil; }
        if (code == 26803)
        { culturalLiteContext.taskCulture = nil; culturalLiteContext.taskCultureEvidence = nil;
          culturalExpandedContext.taskCulture = nil; culturalExpandedContext.taskCultureEvidence = nil;
          makeupContextFixture.taskCulture = nil; makeupContextFixture.taskCultureEvidence = nil; return nil; }
        if (code == 26804)
        { gestureTask.taskCulture = farCulture; rpgLiteScore(crossPhysician,gestureTask); return nil; }
        if (code == 26805)
        { culturalLiteContext.taskCultureEvidence = nil; rpgLiteScore(crossPhysician,culturalLiteContext); return nil; }
        if (code == 26806)
        { makeupContextFixture.taskCulture = nearCulture; makeupApplicationFixture.assess(); return nil; }
        return inherited(context);
    }
;
