#include "expanded-landing-attempt.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-hazards.t>
linkedFall: RpgExpandedFallInjury id = 'impact' profile = bleedProfile fall = landingOccurrence
    landing = landingAttempt damageVelocity = 16 damage = 10 resistance = 10 approved = true
    evidence = 'The authored torso impact damage was resolved at the landing receipt velocity against one armor layer';
linkedDuplicate: RpgExpandedFallInjury id = 'duplicate-impact' profile = bleedProfile fall = landingOccurrence
    damage = 10 resistance = 10 approved = true evidence = 'Duplicate injury for the same occurrence';
otherFall: object;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 880)
        { local value = linkedFall.assess(); event('test.linked-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 881 || code == 882)
        { linkedFall.apply(); if (code == 882) throw new RpgError(); return nil; }
        if (code == 883)
        {
            event('test.linked-fall'); eventValue(bleedProfile.injury); eventValue(bleedProfile.fallInjuries.length());
            eventValue(bleedProfile.expandedWounds.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 884) { linkedFall.damageVelocity = 19; return nil; }
        if (code == 885) { linkedDuplicate.apply(); return nil; }
        if (code == 886) { linkedFall.fall = otherFall; return nil; }
        return inherited(context);
    }
;
