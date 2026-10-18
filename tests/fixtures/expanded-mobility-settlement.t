#include "expanded-crutch-support.t"
mobilitySettlement: RpgExpandedMobilitySettlement support = crutchSupport
    evidence = 'The aid is no longer usable at this occurrence'
    impactResolved = true impactEvidence = 'The authored helper lowers the character onto padding without additional injury';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 990 || code == 991)
        { mobilitySettlement.apply(); if (code == 991) throw new RpgError(); return nil; }
        if (code == 992)
        {
            event('test.mobility-settlement'); eventValue(bleedProfile.mobilitySupport == nil ? 0 : 1);
            eventValue(bleedProfile.posture); eventValue(bleedProfile.mobilitySettlements.length());
            eventValue(bleedProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 993) { mobilitySettlement.impactResolved = nil; return nil; }
        if (code == 994)
        {
            event('test.mobility-clock');
            try { rpgSpendTime(1); eventValue('advanced'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 995) { mobilitySettlement.cause = 'withdrawn'; return nil; }
        return inherited(context);
    }
;
