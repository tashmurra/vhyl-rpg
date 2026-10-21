#include "expanded-ancestry-stacking.t"
navigationPackageOne: RpgExpandedTemplate traitRows = [['orientation-sense',1,nil,nil,['signal-dependent']]];
navigationPackageTwo: RpgExpandedTemplate traitRows = [['orientation-sense',2,nil,nil,['signal-dependent']]];
navigationTemplateState: object profile = nil second = nil;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 9700)
        {
            navigationTemplateState.profile = rpgExpandedCombineTemplates([navigationPackageOne,navigationPackageTwo],bleedRules,100,50);
            navigationTemplateState.second = navigationPackageTwo.create(bleedRules); return nil;
        }
        if (code == 9701)
        {
            local p = navigationTemplateState.profile; event('test.navigation-template');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.traits[1].level); eventValue(p.traits[1].signalDependent ? 1 : 0);
            eventValue(p.traits[1] != navigationTemplateState.second.traits[1] ? 1 : 0); return nil;
        }
        if (code == 9702)
        {
            navigationPackageTwo.traitRows = [['orientation-sense',2,nil]]; event('test.navigation-template-conflict');
            try { rpgExpandedCombineTemplates([navigationPackageOne,navigationPackageTwo],bleedRules,100,50); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 9703 || code == 9704)
        {
            stackFirst.traitRows = [['orientation-sense',2,nil,nil,['signal-dependent']],['free-fall-susceptibility',1,'regular-space-travel']];
            stackSecond.traitRows = stackFirst.traitRows;
            ancestryState.profile = rpgExpandedCreateAncestryCharacter(ancestryPlain,[stackFirst,stackSecond],bleedRules);
            if (code == 9704) throw new RpgError(); return nil;
        }
        if (code == 9705)
        {
            local p = ancestryState.profile; event('test.navigation-ancestry');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.traits.length()); eventValue(p.creationDisadvantageExemption());
            eventValue(p.traits[1].signalDependent ? 1 : 0); eventValue(p.freeFallSusceptible(true) ? 1 : 0);
            foreach (local origins in p.ancestryScores.traitOrigins) eventValue(origins.length()); return nil;
        }
        if (code == 9707)
        {
            stackSecond.traitRows = [['orientation-sense',2,nil],['free-fall-susceptibility',1,'regular-space-travel']];
            event('test.navigation-ancestry-conflict');
            try { rpgExpandedCreateAncestryCharacter(ancestryPlain,[stackFirst,stackSecond],bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 9706)
        {
            ancestryState.profile.traits[1].signalDependent = nil; event('test.navigation-ancestry-binding');
            try { ancestryState.profile.ancestryScores.validate(ancestryState.profile); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            ancestryState.profile.traits[1].signalDependent = true; return nil;
        }
        return inherited(context);
    }
;
