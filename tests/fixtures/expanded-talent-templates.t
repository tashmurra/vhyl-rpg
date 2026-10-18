#include "expanded-ancestry-stacking.t"
talentTemplateState: object first = nil second = nil combined = nil;
talentTemplateOne: RpgExpandedTemplate traitRows = [['medical-aptitude',1,nil]];
talentTemplateTwo: RpgExpandedTemplate traitRows = [['medical-aptitude',2,nil]];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 7300)
        {
            talentTemplateState.first = talentTemplateOne.create(bleedRules);
            talentTemplateState.second = talentTemplateOne.create(bleedRules);
            talentTemplateState.combined = rpgExpandedCombineTemplates([talentTemplateOne,talentTemplateTwo],bleedRules,100,50);
            return nil;
        }
        if (code == 7301)
        {
            local a = talentTemplateState.first; local b = talentTemplateState.second; local c = talentTemplateState.combined;
            event('test.talent-template'); eventValue(a.traits[1] != b.traits[1] && a.traits[1] != c.traits[1] ? 1 : 0);
            eventValue(a.traits[1].level); eventValue(b.traits[1].level); eventValue(c.traits[1].level);
            eventValue(rpgExpandedCharacterCost(c,nil)); return nil;
        }
        if (code == 7302) { talentTemplateState.first.traits[1].level = 3; return nil; }
        if (code == 7303 || code == 7304)
        {
            stackFirst.traitRows = [['medical-aptitude',2,nil]];
            stackSecond.traitRows = [['medical-aptitude',code == 7303 ? 2 : 3,nil]];
            event('test.talent-ancestry');
            try
            {
                ancestryState.profile = rpgExpandedCreateAncestryCharacter(ancestryPlain,[stackFirst,stackSecond],bleedRules);
                eventValue('accepted'); eventValue(rpgExpandedCharacterCost(ancestryState.profile,nil));
            }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
