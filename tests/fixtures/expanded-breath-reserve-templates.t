#include "expanded-breath-reserve-trait.t"
reservePackage: RpgExpandedTemplate
    traitRows = [['breath-reserve',2,nil,nil,['nonhuman','Approved exceptional air storage']]];
reserveOtherPackage: RpgExpandedTemplate
    traitRows = [['breath-reserve',3,nil,nil,['nonhuman','Approved exceptional air storage']]];
reservePersonal: RpgExpandedTemplate;
reserveAncestryOne: RpgExpandedAncestryTemplate id = 'aquatic-lineage' nonhuman = true approved = true evidence = 'Approved lineage'
    traitRows = [['breath-reserve',1,nil,nil,['nonhuman','Approved exceptional air storage']]];
reserveAncestryTwo: RpgExpandedAncestryTemplate id = 'deep-lineage' nonhuman = true approved = true evidence = 'Approved combined lineage'
    traitRows = [['breath-reserve',2,nil,nil,['nonhuman','Approved exceptional air storage']]];
reserveTemplateState: object first = nil second = nil;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 18300)
        {
            reserveTemplateState.first = reservePackage.create(expandedRules);
            reserveTemplateState.second = reservePackage.create(expandedRules);
        }
        else if (code == 18301)
        {
            reserveTemplateState.first = rpgExpandedCombineTemplates([reservePackage,reserveOtherPackage],expandedRules,100,50);
        }
        else if (code == 18302)
        {
            reserveTemplateState.first = rpgExpandedCreateAncestryCharacter(reservePersonal,
                [reserveAncestryOne,reserveAncestryTwo],expandedRules);
        }
        else if (code == 18303)
        {
            local profile = reserveTemplateState.first;
            event('test.reserve-package'); eventValue(profile.purchasedBreathReserveLevels());
            eventValue(rpgExpandedCharacterCost(profile,nil)); eventValue(profile.traits.length()); return nil;
        }
        else if (code == 18304)
        {
            reserveTemplateState.first.traits[1].mitigated = true;
            event('test.reserve-package-isolation'); eventValue(reserveTemplateState.first.purchasedBreathReserveLevels());
            eventValue(reserveTemplateState.second.purchasedBreathReserveLevels()); return nil;
        }
        else if (code == 18305 || code == 18306)
        {
            if (code == 18305) reserveOtherPackage.traitRows = [['breath-reserve',2,nil,nil,['super','Different eligibility']]];
            else reserveOtherPackage.traitRows = [['breath-reserve',2,nil]];
            try { rpgExpandedCombineTemplates([reservePackage,reserveOtherPackage],expandedRules,100,50); }
            catch (RpgExpandedError error) { event('test.reserve-package-error'); eventValue(error.reason); }
            return nil;
        }
        else return inherited(context);
        return nil;
    }
;
