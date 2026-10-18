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
retchRules: RpgExpandedRules scaledInjuryShock = true;
retchProfile: RpgExpandedProfile rules = retchRules;
retchContext: RpgExpandedFearContext profile = retchProfile approved = true evidence = 'Extraordinary scene';
retchEpisode: RpgExpandedFearRetching id = 'fear-retching' context = retchContext approved = true evidence = 'Row twelve' oralEffectsReviewed = true;
retchRecovery: RpgExpandedRetchingRecovery id = 'first-recovery' episode = retchEpisode;
retchSecondRecovery: RpgExpandedRetchingRecovery id = 'second-recovery' episode = retchEpisode;
retchOtherProfile: RpgLiteProfile dx = 9;
retchFighter: RpgLiteFighter profile = retchProfile;
retchOther: RpgLiteFighter profile = retchOtherProfile;
retchBattle: RpgLiteBattle fighters = [retchFighter,retchOther];
retchGate: RpgExpandedActionGate id = 'recover-turn' profile = retchProfile purpose = 'do-nothing' evidence = 'Recover from retching';
retchManeuver: RpgExpandedRetchingRecoveryManeuver battle = retchBattle recovery = retchRecovery healthGate = retchGate;
retchIdle: RpgLiteManeuver;
retchConcentrate: RpgLiteManeuver kind = 'concentrate';
retchNeeds: RpgLiteNeeds profile = retchProfile meals = 0;
retchMeal: RpgExpandedMealCredit id = 'supper' profile = retchProfile needs = retchNeeds approved = true evidence = 'One eaten meal';
retchInput: object code = 0;
class RetchTestAction: Action
    exec(context)
    {
        local code = retchInput.code;
        if (code >= 30)
        {
            if (code == 30 || code == 31)
            {
                local credit = retchMeal.apply(); event('test.retch-meal'); eventValue(credit.status); eventValue(credit.reason);
                if (code == 31) throw new RpgError(); return nil;
            }
            if (code == 32) { retchEpisode.affectedOralBenefits = [retchMeal]; return nil; }
            if (code == 33) { retchEpisode.affectedOralBenefits = [retchMeal,retchMeal]; return nil; }
            if (code == 34) { retchNeeds.elapsed = 86399; retchNeeds.advance(1); return nil; }
            if (code == 35) { retchEpisode.affectedOralBenefits = []; return nil; }
            return nil;
        }
        if (code >= 20)
        {
            if (code == 20) { retchBattle.begin(); rpgRandom.seed(1); return nil; }
            if (code == 25) { retchManeuver.available(retchFighter); return nil; }
            if (code == 26)
            {
                local extra = retchSecondRecovery.apply();
                event('test.retch-extra'); eventValue(extra.status); eventValue(extra.reason); return nil;
            }
            local value = code == 21 ? retchBattle.step(retchFighter,retchIdle)
                : code == 22 ? retchBattle.step(retchOther,retchIdle)
                : code == 27 ? retchBattle.step(retchFighter,retchConcentrate)
                : retchBattle.step(retchFighter,retchManeuver);
            event('test.retch-turn'); eventValue(value.status); eventValue(value.reason);
            if (code == 24) throw new RpgError(); return nil;
        }
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
        if (code == 13) { retchProfile.fatigue = 19; return nil; }
        if (code == 14) { retchProfile.fatigue = 9; return nil; }
        if (code == 15) { rpgRandom.seed(5); return nil; }
        if (code == 16) { retchRules.scaledInjuryShock = nil; return nil; }
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
    if (verb == 2258)
    {
        event('test.retch-costs'); eventValue(retchProfile.injury); eventValue(retchProfile.expandedWounds.length());
        eventValue(retchProfile.unconscious ? 1 : 0);
        eventValue(retchRecovery.result == nil ? 0 : retchRecovery.result.fatigueAdded);
        eventValue(retchRecovery.result == nil ? 0 : retchRecovery.result.injuryAdded); return nil;
    }
    if (verb == 2259)
    {
        event('test.retch-clock'); eventValue(retchBattle.index); eventValue(retchBattle.seconds);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2260)
    {
        event('test.retch-meal-state'); eventValue(retchNeeds.meals); eventValue(retchNeeds.cycle);
        eventValue(retchMeal.revokedBy == retchEpisode ? 1 : 0); eventValue(retchProfile.mealCredits.length()); return nil;
    }
    return nil;
}
