#include "expanded-sustenance-timely-dose.t"
sustenanceInitial: RpgExpandedSustenanceInitialAccess id = 'initial-access' profile = bleedProfile requirement = sustenanceTrait
    approved = true evidence = 'The opening scene begins immediately after sufficient access, already accounted in starting resources';
sustenanceInitialDuplicate: RpgExpandedSustenanceInitialAccess id = 'duplicate-access' profile = bleedProfile requirement = sustenanceTrait
    approved = true evidence = 'A second initial record must not reset the existing requirement';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 12500)
        {
            sustenanceTrait.requirementKind = 'substance'; bleedProfile.traits = [sustenanceTrait];
            bleedProfile.equipment = [sustenanceSupply]; sustenanceDeadline.source = sustenanceInitial; return nil;
        }
        if (code == 12501 || code == 12502)
        { sustenanceInitial.record(); if (code == 12502) throw new RpgError(); return nil; }
        if (code == 12503)
        {
            event('test.sustenance-initial-state'); eventValue(bleedProfile.sustenanceInitialAccess.length());
            eventValue(bleedProfile.sustenanceDeprivations.length()); eventValue(sustenanceSupply.quantity);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 12504)
        {
            event('test.sustenance-initial-duplicate');
            try { sustenanceInitialDuplicate.record(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
