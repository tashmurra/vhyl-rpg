#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-psionics.t>
powerRoom: Room 'Quiet Observatory';
modify gameMain initialRoom = powerRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
warningPower: RpgExpandedPsionicPower id = 'remote-warning' abilityIds = ['danger-sense'] powerModifier = -10
    approved = true evidence = 'Sensory family';
warningTalent: RpgExpandedPsionicTalent id = 'warning-talent' power = warningPower level = 2
    approved = true evidence = 'Paid talent';
warningAbility: RpgExpandedPsionicDangerSense power = warningPower approved = true evidence = 'Paid warning ability';
warningObserver: RpgExpandedProfile iq = 8 traits = [warningTalent,warningAbility];
warningRequest: RpgExpandedDangerWarning id = 'loose-masonry' profile = warningObserver ability = warningAbility
    hazardPresent = true approved = true interferenceKnown = true evidence = 'Stone will fall before the next step'
    warningText = 'Pause: something is wrong.' detailText = 'Loose masonry above the doorway is about to fall.';
warningInput: object code = 0 forcedRoll = 0;
modify rpgRandom
    roll()
    {
        if (warningInput.forcedRoll != 0) { self.draws += 3; return warningInput.forcedRoll; }
        return inherited();
    }
;
class WarningTestAction: Action
    exec(context)
    {
        local code = warningInput.code;
        if (code == 4) warningRequest.suppressed = true;
        if (code == 5) rpgRandom.seed(5);
        if (code == 6) rpgRandom.seed(6);
        if (code == 7) warningInput.forcedRoll = 4;
        if (code == 8) warningInput.forcedRoll = 3;
        if (code == 9) warningRequest.warningText = 'Changed warning';
        local request = warningRequest;
        if (code == 10)
        {
            request = new RpgExpandedDangerWarning(); request.id = warningRequest.id; request.profile = warningObserver;
            request.ability = warningAbility; request.hazardPresent = true; request.approved = true;
            request.interferenceKnown = true; request.evidence = 'Duplicate hazard';
            request.warningText = 'Warning'; request.detailText = 'Details';
        }
        local value = code == 1 ? request.assess() : request.apply();
        event('test.warning'); eventValue(value.status); eventValue(value.reason); eventValue(value.warning);
        if (code == 2) throw new RpgError(); return nil;
    }
;
warningAction: WarningTestAction;
warningVerb: Verb code = 2231 action = warningAction label = 'sense danger';
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2231) { warningInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2232)
    {
        event('test.warning-state'); eventValue(warningObserver.psionicDangerWarnings.length());
        eventValue(warningObserver.lastCheck == nil ? 0 : 1); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
        eventValue(warningAbility.creationCost()); return nil;
    }
    if (verb == 2230)
    {
        local profile = new RpgExpandedProfile();
        local power = new RpgExpandedPsionicPower(); power.id = 'remote-sense';
        power.abilityIds = ['danger-sense']; power.powerModifier = -10;
        power.approved = true; power.evidence = 'Campaign permits this sensory family';
        local talent = new RpgExpandedPsionicTalent(); talent.id = 'remote-sense-talent'; talent.power = power;
        talent.level = args[1]; talent.aboveFourApproved = args[2] != 0;
        talent.approved = true; talent.evidence = 'Owned sensory potential'; talent.active = args[3] != 0;
        profile.traits = [talent];
        if (args[4] == 1) profile.traits = [];
        if (args[4] == 2) { power.broad = true; power.talentPoints = 10; }
        if (args[4] == 3) { power.broad = true; power.talentPoints = 10; power.customTalentPriceApproved = true; }
        if (args[4] == 4) { power.allowsTalent = nil; power.talentPoints = 0; }
        try
        {
        local cost = profile.traits.length() == 0 ? 0 : talent.creationCost();
        local bonus = rpgExpandedPsionicTalentBonus(profile,power);
        local eligibility = rpgExpandedPsionicLatentEligibility(profile,power,args[5]);
        event('test.psionic-talent'); eventValue(cost); eventValue(bonus); eventValue(eligibility.status);
        eventValue(eligibility.reason); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        catch (RpgExpandedError error) { event('test.psionic-reject'); eventValue(error.reason); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); }
    }
    return nil;
}
