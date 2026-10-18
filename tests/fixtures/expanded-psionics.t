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
        if (code >= 11 && code <= 14)
        {
            local owner = new RpgExpandedProfile(); local field = new RpgExpandedPsionicStatic();
            field.areaLevels = 1; field.approved = true; field.evidence = 'Known static field'; owner.traits = [field];
            local contact = new RpgExpandedPsionicStaticContact(); contact.owner = owner; contact.field = field;
            contact.source = warningObserver; contact.target = warningObserver; contact.approved = true;
            contact.evidence = 'Measured relative positions'; contact.sourceDistance = code == 12 ? 2 : 1;
            contact.targetDistance = contact.sourceDistance;
            if (code == 13) { contact.owner = warningObserver; warningObserver.traits = warningObserver.traits + [field]; field.areaLevels = 0; }
            if (code == 14) { field.switchable = true; field.active = nil; }
            warningRequest.staticContacts = [contact];
        }
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
    if (verb == 2234)
    {
        local owner = new RpgExpandedProfile(); local source = new RpgExpandedProfile();
        local target = new RpgExpandedProfile(); local item = new RpgLiteItem();
        local field = new RpgExpandedPsionicStatic(); field.areaLevels = args[1]; field.switchable = args[2] != 0;
        field.active = args[3] != 0; field.approved = true; field.evidence = 'Paid static'; owner.traits = [field];
        local contact = new RpgExpandedPsionicStaticContact(); contact.owner = owner; contact.field = field;
        contact.source = source; contact.target = target; contact.sourceDistance = args[4]; contact.targetDistance = args[5];
        contact.indirectPhysical = args[6] != 0; contact.counterpower = args[7] != 0;
        contact.approved = true; contact.evidence = 'Measured field and direct target';
        if (args[8] == 1) contact.target = owner;
        if (args[8] == 2) { owner.equipment = [item]; contact.target = item; contact.targetCarrier = owner; }
        local value = contact.assess();
        event('test.psionic-static'); eventValue(field.creationCost()); eventValue(field.radius());
        eventValue(value.status); eventValue(value.reason); eventValue(value.suppressed ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2233)
    {
        local profile = new RpgExpandedProfile();
        local resistance = new RpgExpandedPsionicResistance(); resistance.degree = args[1];
        resistance.active = args[2] != 0; resistance.approved = true; resistance.evidence = 'Paid mental protection';
        profile.traits = [resistance];
        local context = new RpgExpandedPsionicResistanceContext(); context.resistanceAllowed = args[3] != 0;
        context.attribute = args[4] == 'will' ? rpgWill : args[4] == 'ht' ? rpgHT : rpgIQ;
        local assessment = rpgExpandedAssessPsionicResistance(profile,context.resistanceAllowed,context.attribute);
        local score = rpgLiteScore(profile,context); local checked = rpgLiteCheck(profile,context);
        event('test.psionic-resistance'); eventValue(resistance.creationCost()); eventValue(assessment.status);
        eventValue(assessment.modifier); eventValue(assessment.immune ? 1 : 0); eventValue(score);
        eventValue(checked.status); eventValue(checked.reason); eventValue(rpgRandom.draws); return nil;
    }
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
