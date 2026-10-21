#include "expanded-fear-acute.t"
comaEpisode: RpgExpandedFearComa id = 'apparition-coma' context = acuteScene approved = true
    evidence = 'The recorded table outcome is an isolated light coma';
comaRecovery: RpgExpandedFearComaRecovery id = 'first-check' episode = comaEpisode;
comaRetry: RpgExpandedFearComaRecovery id = 'next-check' episode = comaEpisode;
comaSecondEpisode: RpgExpandedFearComa id = 'second-coma' context = acuteScene approved = true
    evidence = 'A separately authored incident occurs during the earlier aftereffect';
comaSecondRecovery: RpgExpandedFearComaRecovery id = 'second-episode-check' episode = comaSecondEpisode;
comaTask: RpgLiteContext attribute = rpgIQ;
comaInput: object independent = nil;
modify bleedProfile
    unconsciousRecoveryApartFrom(owner) { return comaInput.independent || inherited(owner); }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 11000) { bleedInput.forcedRoll = 11; return nil; }
        if (code == 11001) { comaEpisode.tableTotal = 29; return nil; }
        if (code == 11002 || code == 11003) { comaEpisode.apply(); if (code == 11003) throw new RpgError(); return nil; }
        if (code == 11004 || code == 11007)
        {
            local value = code == 11004 ? comaRecovery.apply() : comaRetry.apply(); event('test.coma-recovery');
            eventValue(value.status); eventValue(value.reason); eventValue(value.check == nil ? nil : value.check.roll); return nil;
        }
        if (code == 11005) { rpgSpendTime(comaEpisode.nextCheckAt - rpgLedger.seconds); return nil; }
        if (code == 11006) { bleedInput.forcedRoll = 10; return nil; }
        if (code == 11008)
        {
            event('test.coma-state'); eventValue(bleedProfile.fearComaHistory.length()); eventValue(bleedProfile.unconscious ? 1 : 0);
            eventValue(comaEpisode.nextCheckAt); eventValue(comaEpisode.recoveredAt); eventValue(rpgLedger.seconds);
            eventValue(rpgRandom.draws); eventValue(rpgLiteScore(bleedProfile,comaTask)); return nil;
        }
        if (code == 11009) { rpgSpendTime(21599); return nil; }
        if (code == 11010) { rpgSpendTime(1); return nil; }
        if (code == 11011) { comaInput.independent = true; return nil; }
        if (code == 11020 || code == 11021)
        {
            bleedProfile.fearAftermathOverlapPolicy = code == 11020 ? 'sum' : 'worst';
            bleedProfile.fearAftermathOverlapEvidence = 'Author selects aggregation before any episode starts'; return nil;
        }
        if (code == 11022) { comaSecondEpisode.apply(); return nil; }
        if (code == 11023) { rpgSpendTime(1800); bleedInput.forcedRoll = 3; comaSecondRecovery.apply(); return nil; }
        if (code == 11024) { rpgSpendTime(19800); return nil; }
        if (code == 11025) { rpgSpendTime(1800); return nil; }
        if (code == 11012) { event('test.coma-preview'); eventValue(comaEpisode.assess().status); eventValue(rpgRandom.draws); return nil; }
        return inherited(context);
    }
;
