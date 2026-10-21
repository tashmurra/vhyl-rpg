#include "expanded-landing-injury.t"
modify linkedFall damage = 0;
rolledImpact: RpgExpandedFallImpact injury = linkedFall;
impactInput: object die = 4;
modify rpgRandom
    die() { self.draws += 1; return impactInput.die; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 900)
        { local value = rolledImpact.assess(); event('test.impact-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 901 || code == 902)
        { rolledImpact.apply(); if (code == 902) throw new RpgError(); return nil; }
        if (code == 903)
        {
            event('test.impact-owned'); eventValue(bleedProfile.injury); eventValue(bleedProfile.fallImpacts.length());
            eventValue(bleedProfile.fallInjuries.length()); eventValue(bleedProfile.expandedWounds.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            if (rolledImpact.result != nil) { eventValue(rolledImpact.result.damage); eventValue(rolledImpact.result.dice.length()); }
            return nil;
        }
        if (code == 904) { linkedFall.location = 'arm'; return nil; }
        if (code == 905) { rolledImpact.hard = true; return nil; }
        return inherited(context);
    }
;
