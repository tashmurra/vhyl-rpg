#include "expanded-recurrent-pain.t"
modify recurrentPain intervalHours = 1 frequency = 15;
painDay: RpgExpandedRecurrentPainDay
    id = 'pain-day' profile = bleedProfile trait = recurrentPain onsetAt = 10
    approved = true evidence = 'Authored waking onset ten seconds into the day'
;
painRecovery: RpgExpandedRecurrentPainRecovery id = 'first-interval' episode = painDay expectedDue = 3610;
painNextRecovery: RpgExpandedRecurrentPainRecovery id = 'second-interval' episode = painDay expectedDue = 7210;
modify BleedTestAction
    exec(actionContext)
    {
        local code = bleedInput.code;
        if (code == 4600 || code == 4601)
        {
            painDay.resolve(); if (code == 4601) throw new RpgError(); return nil;
        }
        if (code == 4602) { rpgSpendTime(10); return nil; }
        if (code == 4603) { rpgSpendTime(3600); return nil; }
        if (code == 4604 || code == 4606)
        {
            local value = code == 4604 ? painRecovery.apply() : painNextRecovery.apply();
            event('test.recurrent-recovery'); eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 4605) { bleedInput.forcedRoll = 17; return nil; }
        if (code == 4607)
        {
            event('test.recurrent-episode'); eventValue(bleedProfile.recurrentPainDays.length());
            eventValue(painDay.active() ? 1 : 0); eventValue(painDay.dueAt); eventValue(painDay.recoveries.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            local context = new RpgLiteContext(); context.attribute = rpgDX; eventValue(rpgLiteScore(bleedProfile,context));
            context.attribute = rpgIQ; eventValue(rpgLiteScore(bleedProfile,context));
            context.attribute = rpgHT; eventValue(rpgLiteScore(bleedProfile,context));
            eventValue(bleedProfile.healthSelfControlModifier(recurrentPain)); return nil;
        }
        return inherited(actionContext);
    }
;
