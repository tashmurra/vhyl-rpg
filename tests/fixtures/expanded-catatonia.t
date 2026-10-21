#include "expanded-fear-acute.t"
catEpisode: RpgExpandedCatatonia id = 'apparition-catatonia' context = acuteScene approved = true careMode = 'none'
    evidence = 'The recorded fear-table outcome is thirty';
catDay: RpgExpandedCatatoniaDay id = 'cat-day-one' episode = catEpisode approved = true evidence = 'Author confirms the first day had no medical care';
catSecondDay: RpgExpandedCatatoniaDay id = 'cat-day-two' episode = catEpisode approved = true evidence = 'Author confirms the second day had no medical care';
catRecovery: RpgExpandedCatatoniaRecovery id = 'first-check' episode = catEpisode;
catRetry: RpgExpandedCatatoniaRecovery id = 'second-check' episode = catEpisode;
catTask: RpgLiteContext attribute = rpgHT kind = 'resistance';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 11100) { bleedInput.forcedRoll = 11; catEpisode.apply(); return nil; }
        if (code == 11101) { rpgSpendTime(86400); return nil; }
        if (code == 11102 || code == 11103 || code == 11104)
        {
            if (code == 11103) catSecondDay.apply(); else catDay.apply();
            if (code == 11104) throw new RpgError(); return nil;
        }
        if (code == 11105 || code == 11106)
        {
            local value = code == 11105 ? catRecovery.apply() : catRetry.apply();
            event('test.cat-recovery'); eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 11107) { bleedInput.forcedRoll = 10; return nil; }
        if (code == 11108)
        {
            event('test.cat-state'); eventValue(catEpisode.days.length()); eventValue(bleedProfile.injury);
            eventValue(bleedProfile.catatonia != nil ? 1 : 0); eventValue(catEpisode.nextCheckAt); eventValue(catEpisode.recoveredAt);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); eventValue(rpgLiteScore(bleedProfile,catTask)); return nil;
        }
        if (code == 11109)
        {
            catEpisode.careMode = 'continuous'; catDay.careProvided = true; catSecondDay.careProvided = true; return nil;
        }
        if (code == 11112 || code == 11113)
        {
            catEpisode.careMode = 'daily'; catEpisode.neglectPolicy = code == 11112 ? 'elapsed-days' : 'uncared-days';
            catEpisode.neglectEvidence = 'Author selects how intermittent care affects escalation';
            catDay.careProvided = true; catSecondDay.careProvided = nil; return nil;
        }
        if (code == 11114) { bleedProfile.unconscious = true; return nil; }
        if (code == 11115) { event('test.cat-unconscious'); eventValue(bleedProfile.unconscious ? 1 : 0); return nil; }
        if (code == 11110) { rpgSpendTime(172800); return nil; }
        if (code == 11111)
        {
            event('test.cat-clock');
            try { rpgSpendTime(86401); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
