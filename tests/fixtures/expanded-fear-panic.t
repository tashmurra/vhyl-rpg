#include "expanded-fear-acute.t"
panicEpisode: RpgExpandedFearPanic id = 'apparition-panic' context = acuteScene approved = true
    evidence = 'The recorded fear-table outcome is twenty-one' behaviorKind = 'cry'
    behavior = 'The character sits and cries without pursuing the current objective';
panicRecovery: RpgExpandedFearPanicRecovery id = 'first-minute' episode = panicEpisode;
panicRetry: RpgExpandedFearPanicRecovery id = 'next-minute' episode = panicEpisode;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10611) { bleedProfile.unconscious = true; bleedProfile.stunned = true; return nil; }
        if (code == 10612)
        {
            event('test.panic-incapacity'); eventValue(bleedProfile.unconscious ? 1 : 0);
            eventValue(bleedProfile.stunned ? 1 : 0); return nil;
        }
        if (code == 10600) { bleedInput.forcedRoll = 11; return nil; }
        if (code == 10601) { event('test.panic-preview'); eventValue(panicEpisode.assess().status); eventValue(rpgRandom.draws); return nil; }
        if (code == 10602 || code == 10603) { panicEpisode.apply(); if (code == 10603) throw new RpgError(); return nil; }
        if (code == 10604)
        {
            event('test.panic-state'); eventValue(bleedProfile.fearPanicEpisodes.length()); eventValue(bleedProfile.fearPanic == panicEpisode ? 1 : 0);
            eventValue(panicEpisode.nextCheckAt); eventValue(panicEpisode.completedAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10605) { rpgSpendTime(60); return nil; }
        if (code == 10606 || code == 10607 || code == 10610)
        {
            local value = code == 10607 ? panicRetry.apply() : panicRecovery.apply();
            event('test.panic-recovery'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.check == nil ? nil : value.check.score); eventValue(value.check != nil && value.check.achieved ? 1 : 0);
            if (code == 10610) throw new RpgError(); return nil;
        }
        if (code == 10608) { bleedProfile.will = 20; bleedInput.forcedRoll = 14; return nil; }
        if (code == 10609)
        {
            event('test.panic-clock');
            try { rpgSpendTime(61); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
