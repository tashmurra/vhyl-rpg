#include "expanded-fall-impact.t"
#include <vhyl-rpg-expanded-traits.t>
fallJumpTrait: RpgExpandedEnhancedJump level = 2 approved = true;
modify bleedProfile traits = [fallJumpTrait];
fallJumpDistance: RpgExpandedJumpDistance profile = bleedProfile;
jumpProtection: RpgExpandedJumpFallProtection id = 'jump-protection' profile = bleedProfile
    fall = landingOccurrence distance = 4 jumping = fallJumpDistance;
modify linkedFall landing = jumpProtection resistance = 0;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1320 || code == 1321)
        {
            jumpProtection.resolve(); linkedFall.damageVelocity = jumpProtection.result.velocity;
            if (code == 1321) throw new RpgError(); return nil;
        }
        if (code == 1322)
        {
            local value = jumpProtection.assess(); event('test.jump-protection');
            eventValue(value.status); eventValue(value.reason);
            eventValue(bleedProfile.jumpFallProtections.length()); eventValue(rpgRandom.draws);
            if (jumpProtection.result != nil)
            { eventValue(jumpProtection.result.negatesDamage ? 1 : 0); eventValue(jumpProtection.result.effectiveDistance); }
            return nil;
        }
        if (code == 1323) { jumpProtection.distance = 5; return nil; }
        if (code == 1324)
        { jumpProtection.distance = 9; landingAttempt.distance = 9; jumpProtection.acrobatics = landingAttempt; return nil; }
        if (code == 1325) { fallJumpTrait.mitigated = true; return nil; }
        return inherited(context);
    }
;
