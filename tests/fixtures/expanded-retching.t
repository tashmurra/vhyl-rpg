#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
retchRoom: Room 'Courtyard';
retchRules: RpgExpandedRules;
retchProfile: RpgExpandedProfile rules = retchRules;
retchContext: RpgExpandedFearContext profile = retchProfile approved = true evidence = 'Extraordinary scene';
retchEpisode: RpgExpandedFearRetching id = 'fear-retching' context = retchContext approved = true evidence = 'Row twelve' oralEffectsReviewed = true;
retchRecovery: RpgExpandedRetchingRecovery id = 'first-recovery' episode = retchEpisode;
retchInput: object code = 0;
class RetchTestAction: Action
    exec(context)
    {
        local code = retchInput.code;
        if (code <= 2)
        {
            local value = code == 1 ? retchEpisode.assess() : retchEpisode.apply();
            event('test.retch-start'); eventValue(value.status); eventValue(value.reason);
            if (code == 2) throw new RpgError(); return nil;
        }
        if (code == 3) { rpgSpendTime(15); return nil; }
        if (code == 7) { retchProfile.fatigue = 10; return nil; }
        if (code == 8) { retchEpisode.affectedOralBenefits = ['oral-treatment']; return nil; }
        if (code == 9) { retchEpisode.oralEffectsReviewed = nil; return nil; }
        if (code == 10) { rpgSpendTime(14); return nil; }
        if (code == 11) { rpgSpendTime(1); return nil; }
        if (code == 12)
        {
            local attempt = new RpgLiteContext(); attempt.attribute = rpgIQ; attempt.requiresConcentration = true;
            local check = rpgLiteCheck(retchProfile,attempt);
            event('test.retch-concentrate'); eventValue(check.reason); return nil;
        }
        local value = code == 6 ? retchRecovery.assess() : retchRecovery.apply();
        event('test.retch-recovery'); eventValue(value.status); eventValue(value.reason);
        if (code == 5) throw new RpgError(); return nil;
    }
;
retchAction: RetchTestAction;
retchVerb: Verb code = 2255 action = retchAction label = 'retching operation';
modify gameMain initialRoom = retchRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2255) { retchInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2256)
    {
        event('test.retch-state'); eventValue(retchProfile.retchingEpisode != nil ? 1 : 0);
        eventValue(retchProfile.fatigue); eventValue(retchProfile.retchingHistory.length()); eventValue(retchEpisode.recoveries.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2257)
    {
        event('test.retch-scores');
        foreach (local attribute in [rpgST,rpgDX,rpgIQ,rpgHT,rpgWill,rpgPerception])
        { local context = new RpgLiteContext(); context.attribute = attribute; eventValue(rpgLiteScore(retchProfile,context)); }
        eventValue(retchProfile.mentalStun ? 1 : 0); eventValue(retchProfile.healthDefensePenalty());
        eventValue(retchProfile.healthManeuverReason('concentrate')); return nil;
    }
    return nil;
}
