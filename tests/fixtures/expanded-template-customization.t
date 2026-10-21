#include "expanded-template-isolation.t"
personalBase: RpgExpandedTemplate
    traitRows = [['charisma',1,nil],['unluckiness',1,nil]]
    skillRows = [[learningSkill,1]]
    disadvantageLimit = 15
;
personalChanges: RpgExpandedTemplateOption
    stChange = 1
    skillRows = [[learningSkill,1]]
    traitRows = [['quirk',1,'collects maps']]
;
personalRequest: RpgExpandedTemplateCustomization
    template = personalBase
    additions = personalChanges
    approved = true
    evidence = 'Approved individual occupational changes'
;
personalState: object profile = nil;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 5700)
        {
            personalState.profile = personalRequest.create(bleedRules); return nil;
        }
        if (code == 5701)
        {
            local p = personalState.profile; event('test.template-personal');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(rpgExpandedCharacterCost(p,true));
            eventValue(p.st); eventValue(p.traits.length()); eventValue(p.skills[1].points);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 5702)
        {
            personalRequest.removeTraits = [['unluckiness',nil]];
            personalChanges.traitRows = [['luck',1,nil]]; return nil;
        }
        if (code == 5703) { personalRequest.removeSkills = [learningSkill]; return nil; }
        if (code == 5704) { personalChanges.traitRows = [['vow',2,nil]]; return nil; }
        if (code == 5705)
        {
            personalChanges.traitRows = [['quirk',1,'a'],['quirk',1,'b'],['quirk',1,'c'],
                ['quirk',1,'d'],['quirk',1,'e'],['quirk',1,'f']]; return nil;
        }
        if (code == 5706) { personalRequest.approved = nil; return nil; }
        if (code == 5707) { personalRequest.removeTraits = [['missing',nil]]; return nil; }
        if (code == 5708)
        {
            event('test.template-personal-error');
            try { personalRequest.create(bleedRules); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 5709)
        {
            local p = personalBase.create(bleedRules); event('test.template-personal-base');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.st); eventValue(p.skills[1].points);
            eventValue(p.traits.length()); return nil;
        }
        return inherited(context);
    }
;
