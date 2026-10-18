#include "expanded-behavior-templates.t"
isolationState: object source = nil combined = nil;
isolationFirst: RpgExpandedTemplate
    traitRows = [['charisma',1,nil]]
    create(rules)
    {
        local profile = inherited(rules); isolationState.source = profile; return profile;
    }
;
isolationCustomized: RpgExpandedTemplate
    traitRows = [['charisma',1,nil]]
    change = 0
    create(rules)
    {
        local profile = inherited(rules); local trait = profile.traits[1];
        if (self.change == 1) trait.points = 6;
        if (self.change == 2) trait.active = nil;
        if (self.change == 3) trait.mitigated = true;
        if (self.change == 4) trait.skills = [learningSkill];
        if (self.change == 5) trait.nextCheck = 1;
        return profile;
    }
;
isolationSecond: RpgExpandedTemplate traitRows = [['charisma',2,nil]];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 5610 && code <= 5615)
        {
            isolationCustomized.change = code - 5610;
            event('test.template-customization');
            try
            {
                rpgExpandedCombineTemplates([isolationFirst,isolationCustomized],bleedRules,100,50);
                eventValue('accepted');
            }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            try
            {
                rpgExpandedCombineTemplates([isolationCustomized,isolationFirst],bleedRules,100,50);
                eventValue('accepted');
            }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 5600)
        {
            isolationState.combined = rpgExpandedCombineTemplates([isolationFirst,isolationSecond],bleedRules,100,50);
            return nil;
        }
        if (code == 5601) { isolationState.combined.traits[1].level = 3; return nil; }
        if (code == 5602)
        {
            event('test.template-isolation'); eventValue(isolationState.source.traits[1].level);
            eventValue(isolationState.combined.traits[1].level);
            eventValue(isolationState.source.traits[1] == isolationState.combined.traits[1] ? 1 : 0);
            eventValue(rpgExpandedCharacterCost(isolationState.source,nil));
            eventValue(rpgExpandedCharacterCost(isolationState.combined,nil)); return nil;
        }
        return inherited(context);
    }
;
