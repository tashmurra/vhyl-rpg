#include "expanded-dependent-templates.t"
dependentChoiceOption: RpgExpandedTemplateOption id = 'guardian' contributionDefinitions = [dependentPrototype];
dependentChoiceGroup: RpgExpandedTemplateChoice id = 'responsibility' options = [dependentChoiceOption]
    minimumPoints = -20 maximumPoints = -20;
dependentChoicePackage: RpgExpandedTemplate choiceGroups = [dependentChoiceGroup];
dependentGroupIdentity: object;
dependentGroupPrototype: RpgExpandedDependent id = 'pupils' dependent = dependentGroupIdentity principalPoints = 200
    dependentPoints = 50 importance = 'friend' frequency = 12 group = true approved = true evidence = 'Approved group';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 13700)
        { event('test.dependent-choice-price'); eventValue(dependentChoiceOption.cost()); eventValue(dependentPrototype.owner == nil ? 1 : 0); return nil; }
        if (code == 13701 || code == 13702)
        {
            try
            {
                dependentTemplateState.first = dependentChoicePackage.createSelected(bleedRules,[['responsibility',['guardian']]]);
                event('test.dependent-choice-result'); eventValue('resolved');
            }
            catch (RpgExpandedError error) { event('test.dependent-choice-result'); eventValue(error.reason); }
            if (code == 13702) throw new RpgError(); return nil;
        }
        if (code == 13703) { dependentChoiceGroup.minimumPoints = -19; dependentChoiceGroup.maximumPoints = -19; return nil; }
        if (code == 13704) { dependentChoicePackage.contributionDefinitions = [dependentGroupPrototype]; return nil; }
        if (code == 13705) { dependentChoicePackage.disadvantageLimit = 19; return nil; }
        if (code == 13706)
        {
            event('test.dependent-choice-state'); local profile = dependentTemplateState.first;
            eventValue(profile == nil ? 0 : 1);
            if (profile != nil)
            {
                eventValue(profile.contributions.length()); eventValue(rpgExpandedCharacterCost(profile,nil));
                eventValue(profile.contributions[1].owner == profile ? 1 : 0);
                eventValue(profile.templateChoices.length()); eventValue(profile.dependentSessions.length());
            }
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
