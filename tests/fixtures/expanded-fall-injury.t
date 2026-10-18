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
        return inherited(context);
    }
;
