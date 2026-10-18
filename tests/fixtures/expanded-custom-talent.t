#include "expanded-talent-reaction.t"
customTalentState: object purchase = nil;
customTalentContext: RpgLiteContext skill = studyTalentSkill;
customTalentOther: RpgExpandedProfile rules = bleedRules;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 7400 && code <= 7403)
        {
            local ids = ['mechanic','carpentry','smith','armoury','electrician','machinist'];
            if (code >= 7401) ids = ids + ['masonry'];
            if (code >= 7402) ids = ids + ['engineer','electronics-repair','artist','sewing','jeweler'];
            if (code >= 7403) ids = ids + ['leatherworking'];
            customTalentState.purchase = rpgExpandedMakeCustomTalent(bleedProfile,'workshop-aptitude',ids,2,true,
                'Campaign author approves the related workshop skills and standard size-based price');
            bleedProfile.traits = [customTalentState.purchase];
            talentReactionContext.talent = customTalentState.purchase; return nil;
        }
        if (code == 7410)
        {
            event('test.custom-talent'); eventValue(customTalentState.purchase.creationCost());
            eventValue(bleedProfile.skillScore(studyTalentSkill)); eventValue(bleedProfile.studyTimePercent(studyTalentSkill));
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7411) { customTalentState.purchase.skillIds = ['unrelated']; return nil; }
        if (code == 7412) { customTalentOther.traits = [customTalentState.purchase]; return nil; }
        if (code == 7413) { customTalentState.purchase.approved = nil; return nil; }
        if (code == 7414) { customTalentState.purchase.points = 1; return nil; }
        if (code == 7415)
        {
            event('test.custom-talent-error');
            try { rpgLiteCheck(bleedProfile,customTalentContext); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7416) { customTalentState.purchase.mitigated = true; return nil; }
        return inherited(context);
    }
;
