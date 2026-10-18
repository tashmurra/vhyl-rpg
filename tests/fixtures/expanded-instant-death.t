#include "expanded-bleeding.t"
instantDeath: RpgExpandedInstantDeath id = 'authored-lethal-attack' profile = bleedProfile
    approved = true evidence = 'Author confirms a helpless victim and an obviously lethal attack'
    helpless = true obviouslyLethal = true
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 7500 || code == 7501)
        {
            local value = code == 7500 ? instantDeath.assess() : instantDeath.apply();
            event('test.instant-death'); eventValue(value.status); eventValue(value.reason); eventValue(value.injuryAdded); return nil;
        }
        if (code == 7502)
        {
            event('test.instant-death-state'); eventValue(bleedProfile.hp()); eventValue(bleedProfile.dead ? 1 : 0);
            eventValue(bleedProfile.unconscious ? 1 : 0); eventValue(bleedProfile.instantDeathHistory.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 7503) { instantDeath.helpless = nil; return nil; }
        if (code == 7504) { bleedProfile.unconscious = true; return nil; }
        if (code == 7505) { instantDeath.obviouslyLethal = nil; return nil; }
        if (code == 7506) { instantDeath.approved = nil; return nil; }
        if (code == 7507) { bleedProfile.injury = 5; return nil; }
        if (code == 7508) { instantDeath.apply(); throw new RpgError(); }
        if (code == 7509) { instantDeath.id = 'changed'; return nil; }
        if (code == 7510)
        {
            event('test.instant-death-error');
            try { instantDeath.apply(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
