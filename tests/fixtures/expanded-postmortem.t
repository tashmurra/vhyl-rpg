#include "expanded-instant-death.t"
postmortemReceipt: RpgExpandedPostmortemInjury id = 'later-injury' profile = bleedProfile amount = 50
    approved = true evidence = 'Fifty points of final injury from the authored resolved damage';
postmortemLite: RpgLiteProfile dead = true injury = 60;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 7600) { bleedRules.retainPostmortemInjury = true; instantDeath.apply(); return nil; }
        if (code == 7601 || code == 7602)
        {
            local value = code == 7601 ? postmortemReceipt.assess() : postmortemReceipt.apply();
            event('test.postmortem'); eventValue(value.status); eventValue(value.reason); eventValue(value.injuryAdded); return nil;
        }
        if (code == 7603)
        {
            event('test.postmortem-state'); eventValue(bleedProfile.hp()); eventValue(bleedProfile.dead ? 1 : 0);
            eventValue(bleedProfile.postmortemHistory.length()); eventValue(bleedProfile.shock);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7604) { rpgLiteWound(bleedProfile,5); return nil; }
        if (code == 7605) { postmortemReceipt.apply(); throw new RpgError(); }
        if (code == 7606) { bleedRules.retainPostmortemInjury = nil; return nil; }
        if (code == 7607)
        {
            local value = rpgLiteWound(postmortemLite,5);
            event('test.postmortem-lite'); eventValue(value.injury); eventValue(postmortemLite.injury); return nil;
        }
        if (code == 7608) { bleedRules.retainPostmortemInjury = true; return nil; }
        return inherited(context);
    }
;
