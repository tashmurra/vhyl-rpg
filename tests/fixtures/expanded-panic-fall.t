#include "expanded-extreme-panic.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-hazards.t>
panicLanding: Room 'Lower Landing';
panicFallOccurrence: object;
panicFallInjury: RpgExpandedFallInjury id = 'panic-fall' profile = fearProfile fall = panicFallOccurrence
    damageVelocity = 8 approved = true evidence = 'The authored route ends in a three-yard fall';
panicFallImpact: RpgExpandedFallImpact injury = panicFallInjury;
panicFall: RpgExpandedPanicFallOperation profile = fearProfile actor = player origin = fearRoom destination = panicLanding
    impact = panicFallImpact approved = true evidence = 'The fleeing character falls from the unguarded gallery';
modify player rpgProfile = fearProfile;
modify extremeFirst kind = 'world-operation' operation = panicFall;
modify rpgRandom die() { self.draws += 1; return 4; };
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 620)
        { local v = extremeFirst.assess(); event('test.panic-fall-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 621)
        {
            event('test.panic-fall'); eventValue(location.get(player) == panicLanding ? 1 : 0);
            eventValue(fearProfile.fallImpacts.length()); eventValue(fearProfile.fallInjuries.length());
            eventValue(fearProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 622) { panicFall.evidence = nil; return nil; }
        if (code == 623) { panicFall.destination = fearRoom; extremeFirst.assess(); return nil; }
        return inherited(context);
    }
;
