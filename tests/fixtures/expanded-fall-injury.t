#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-hazards.t>
fallInjury: RpgExpandedFallInjury id = 'landing' profile = bleedProfile damage = 10 resistance = 10
    approved = true evidence = 'Resolved crushing fall damage, torso without location rules, one armor layer';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 830)
        { local value = fallInjury.assess(); event('test.fall-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 831 || code == 832)
        { fallInjury.apply(); if (code == 832) throw new RpgError(); return nil; }
        if (code == 833)
        {
            event('test.fall-owned'); eventValue(bleedProfile.injury); eventValue(bleedProfile.fallInjuries.length());
            eventValue(bleedProfile.expandedWounds.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 834) { fallInjury.location = 'arm'; return nil; }
        if (code == 835) { fallInjury.protectionKind = 'innate'; return nil; }
        if (code == 836) { fallInjury.damage = 11; return nil; }
        if (code == 837) { fallInjury.damage = 20; fallInjury.resistance = 0; fallInjury.obstacleHP = 2; fallInjury.obstacleDR = 1; return nil; }
        if (code == 838) { fallInjury.obstacleDR = nil; return nil; }
        if (code == 839) { fallInjury.resistance = 10; return nil; }
        if (code == 840) { fallInjury.cushionDR = 2; fallInjury.cushionEvidence = 'An authored feather bed cushions this landing'; return nil; }
        if (code == 841) { fallInjury.cushionDR = 10; fallInjury.cushionEvidence = 'An intact safety net cushions this landing'; return nil; }
        if (code == 842) { fallInjury.cushionEvidence = nil; return nil; }
        if (code == 843) { fallInjury.cushionDR = 1; return nil; }
        if (code == 844)
        {
            local value = fallInjury.assess();
            event('test.fall-cushion'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.impactDamage); eventValue(value.cushionedDamage);
            if (value.protection != nil) { eventValue(value.protection.penetratingDamage); eventValue(value.protection.bluntInjury); }
            return nil;
        }
        return inherited(context);
    }
;
