#include "expanded-cultures.t"
culturePackage: RpgExpandedTemplate nativeCulture = homeCulture
    traitRows = [['cultural-familiarity',1,nil,nil,[nearCulture,nil,'Related culture learned during upbringing']]];
alienCulturePackage: RpgExpandedTemplate nativeCulture = homeCulture
    traitRows = [['cultural-familiarity',1,nil,nil,[farCulture,true,'Alien culture learned during an exchange']]];
conflictCulturePackage: RpgExpandedTemplate nativeCulture = farCulture;
cultureCreated: object first = nil second = nil combined = nil selected = nil;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 26300)
        {
            cultureCreated.first = culturePackage.create(healthRules); cultureCreated.second = culturePackage.create(healthRules);
            cultureCreated.combined = rpgExpandedCombineTemplates([culturePackage,alienCulturePackage,culturePackage],healthRules,100,50);
            cultureCreated.selected = culturePackage.createSelected(healthRules,[]); return nil;
        }
        if (code == 26301)
        {
            event('test.culture-template');
            eventValue(cultureCreated.first.nativeCulture == homeCulture ? 1 : 0);
            eventValue(cultureCreated.first.traits[1] != cultureCreated.second.traits[1] ? 1 : 0);
            eventValue(cultureCreated.first.culturalPenalty(nearCulture));
            eventValue(cultureCreated.second.culturalPenalty(nearCulture));
            eventValue(cultureCreated.combined.traits.length());
            eventValue(cultureCreated.combined.traits[1].creationCost() + cultureCreated.combined.traits[2].creationCost());
            eventValue(cultureCreated.selected.culturalPenalty(nearCulture)); return nil;
        }
        if (code == 26302) { cultureCreated.first.traits[1].mitigated = true; return nil; }
        if (code == 26303)
        { cultureCreated.combined = rpgExpandedCombineTemplates([culturePackage,conflictCulturePackage],healthRules,100,50); return nil; }
        if (code == 26304)
        { culturePackage.nativeCulture = nearCulture; culturePackage.create(healthRules); return nil; }
        if (code == 26305)
        { alienCulturePackage.traitRows = [['cultural-familiarity',1,nil]]; alienCulturePackage.create(healthRules); return nil; }
        return inherited(context);
    }
;
