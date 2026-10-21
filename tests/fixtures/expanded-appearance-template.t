#include "expanded-appearance.t"
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-templates.t>
appearancePackage: RpgExpandedTemplate
    traitRows = [['appearance',1,nil,nil,[2,'ordinary',true,true]],['sympathy',1,nil],['social-inhibition',2,nil]];
appearanceCreated: object first = nil second = nil copy = nil;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 24900)
        {
            appearanceCreated.first = appearancePackage.create(healthRules);
            appearanceCreated.second = appearancePackage.create(healthRules);
            appearanceCreated.copy = rpgExpandedCopyTemplateTrait(appearanceCreated.first.appearanceTrait());
            return nil;
        }
        if (code == 24901)
        {
            local first = appearanceCreated.first; local second = appearanceCreated.second; local copy = appearanceCreated.copy;
            event('test.appearance-template'); eventValue(first.appearanceTrait().creationCost());
            eventValue(second.appearanceTrait().creationCost()); eventValue(copy.creationCost());
            eventValue(first.sympathyActive() ? 1 : 0); eventValue(first.socialInhibitionPenalty());
            eventValue(first.appearanceTrait() != second.appearanceTrait() && copy != first.appearanceTrait() ? 1 : 0); return nil;
        }
        if (code == 24902) { appearanceCreated.first.appearanceTrait().standardized = nil; return nil; }
        if (code == 24903)
        {
            appearancePackage.traitRows = [['appearance',1,nil]];
            try { appearancePackage.create(healthRules); }
            catch (RpgExpandedError error) { event('test.appearance-template-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
