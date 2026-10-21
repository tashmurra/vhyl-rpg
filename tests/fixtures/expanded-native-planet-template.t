#include "expanded-biology-skill.t"
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-templates.t>
nativePlanetTemplate: RpgExpandedTemplate iq = 12 campaignTL = 8 nativePlanetType = 'habitable';
unsetPlanetTemplate: RpgExpandedTemplate campaignTL = 8;
foreignPlanetTemplate: RpgExpandedTemplate campaignTL = 8 nativePlanetType = 'rocky';
planetTemplateState: object profile = nil;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 21400 || code == 21401)
        { planetTemplateState.profile = nativePlanetTemplate.create(healthRules); if (code == 21401) throw new RpgError(); return nil; }
        if (code == 21402)
        { planetTemplateState.profile = rpgExpandedCombineTemplates([unsetPlanetTemplate,nativePlanetTemplate],healthRules,100,50); return nil; }
        if (code == 21403)
        {
            local p = planetTemplateState.profile; event('test.planet-template'); eventValue(p == nil ? nil : p.nativePlanetType);
            eventValue(p == nil ? nil : p.skillScore(biologyCatalogue)); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 21404 || code == 21405)
        {
            try
            {
                if (code == 21404) rpgExpandedCombineTemplates([nativePlanetTemplate,foreignPlanetTemplate],healthRules,100,50);
                else { nativePlanetTemplate.nativePlanetType = 'unknown'; nativePlanetTemplate.create(healthRules); }
            }
            catch (RpgExpandedError error) { event('test.planet-template-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 21406) { planetTemplateState.profile.nativePlanetType = 'rocky'; return nil; }
        return inherited(context);
    }
;
