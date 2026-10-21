#include "expanded-fall-lower.t"
pegItem: RpgLiteItem id = 'fitted-peg' worn = true;
modify bleedProfile equipment = [pegItem];
modify fallInjury damage = 16;
pegSupport: RpgExpandedPegSupport profile = bleedProfile leg = fallArm item = pegItem
    fitted = true terrainSuitable = true approved = true
    evidence = 'This owned peg has already been fitted; the authored route permits supported walking';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 970 || code == 971)
        { pegSupport.activate(); if (code == 971) throw new RpgError(); return nil; }
        if (code == 972)
        {
            event('test.peg-support'); eventValue(bleedProfile.injury);
            eventValue(bleedProfile.mobilitySupport == pegSupport ? 1 : 0);
            try { eventValue(bleedProfile.move()); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(bleedProfile.posture); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 973) { pegItem.worn = nil; return nil; }
        if (code == 974) { pegSupport.terrainSuitable = nil; return nil; }
        if (code == 975)
        {
            local reason = bleedProfile.postureChangeReason('standing');
            if (reason != nil) rpgExpandedReject(reason);
            bleedProfile.posture = 'standing'; return nil;
        }
        if (code == 976) { pegSupport.deactivate(); return nil; }
        if (code == 977) { pegItem.weight = 3000; return nil; }
        if (code == 978) { bleedProfile.fatigue = 7; return nil; }
        if (code == 979) { bleedProfile.posture = 'sitting'; return nil; }
        return inherited(context);
    }
;
