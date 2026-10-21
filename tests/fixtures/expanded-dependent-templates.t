#include "expanded-dependents.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-templates.t>
dependentPrototype: RpgExpandedDependent id = 'ward' dependent = dependentPerson principalPoints = 200
    dependentPoints = 50 importance = 'friend' frequency = 12 approved = true evidence = 'Approved template relationship';
dependentPackage: RpgExpandedTemplate contributionDefinitions = [dependentPrototype];
dependentTemplateState: object first = nil second = nil;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 13600 || code == 13601)
        {
            dependentTemplateState.first = dependentPackage.create(bleedRules);
            dependentTemplateState.second = dependentPackage.createSelected(bleedRules,[]);
            if (code == 13601) throw new RpgError(); return nil;
        }
        if (code == 13602)
        {
            event('test.dependent-template');
            local first = dependentTemplateState.first; local second = dependentTemplateState.second;
            eventValue(first == nil ? 0 : 1); eventValue(second == nil ? 0 : 1);
            if (first != nil && second != nil)
            {
                eventValue(first.contributions[1] != second.contributions[1] ? 1 : 0);
                eventValue(first.contributions[1].owner == first ? 1 : 0);
                eventValue(second.contributions[1].owner == second ? 1 : 0);
                eventValue(dependentPrototype.owner == nil ? 1 : 0);
                eventValue(rpgExpandedCharacterCost(first,nil)); eventValue(rpgExpandedCharacterCost(second,nil));
                eventValue(first.dependentAppearances.length()); eventValue(second.dependentSessions.length());
            }
            return nil;
        }
        if (code == 13603)
        { dependentTemplateState.first.contributions[1].importance = 'loved-one'; return nil; }
        if (code == 13604)
        {
            dependentPackage.contributionDefinitions = [dependentRelationship];
            try { dependentPackage.create(bleedRules); }
            catch (RpgExpandedError error) { event('test.dependent-template-rejection'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
