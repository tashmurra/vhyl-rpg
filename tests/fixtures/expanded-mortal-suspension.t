#include "expanded-trauma-maintenance.t"
mortalSuspension: RpgExpandedMortalSuspension id = 'stasis' patient = bleedProfile kind = 'advanced-technology'
    approved = true effectEvidence = 'An independently resolved suspension effect holds the patient unconscious';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 200) { rpgSpendTime(600); return nil; }
        if (code == 201) { mortalSuspension.assess(); return nil; }
        if (code == 202 || code == 203)
        { mortalSuspension.start(); if (code == 203) throw new RpgError(); return nil; }
        if (code == 204) { mortalSuspension.end(); return nil; }
        if (code == 205) { rpgSpendTime(1200); return nil; }
        if (code == 206)
        {
            event('test.mortal-suspension'); eventValue(mortalSuspension.startedAt); eventValue(mortalSuspension.endedAt);
            eventValue(bleedProfile.mortalClock); eventValue(bleedProfile.mortalSuspensionHistory.length());
            eventValue(bleedProfile.mortal ? 1 : 0); eventValue(bleedProfile.unconscious ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 207) { mortalSuspension.approved = nil; return nil; }
        if (code == 208) { rpgLiteHeal(bleedProfile,1); return nil; }
        return inherited(context);
    }
;
