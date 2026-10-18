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
warningRules: RpgExpandedRules;
modify warningObserver rules = warningRules creationComplete = true developmentOpen = true earnedPoints = 20 unspentPoints = 20;
warningAdvancement: RpgExpandedPsionicTalentAdvancement id = 'improve-warning' profile = warningObserver
    talent = warningTalent targetLevel = 4 permitted = true evidence = 'Practice during downtime';

latentTalent: RpgExpandedPsionicTalent id = 'latent-talent' power = warningPower level = 2
    approved = true evidence = 'Owned latent potential';
latentProfile: RpgExpandedProfile iq = 8 traits = [latentTalent] rules = warningRules creationComplete = true
    developmentOpen = true earnedPoints = 20 unspentPoints = 20;
latentAbility: RpgExpandedPsionicDangerSense power = warningPower approved = true evidence = 'Approved warning ability';
latentPurchase: RpgExpandedDangerSensePurchase id = 'first-warning' profile = latentProfile ability = latentAbility
    permitted = true evidence = 'Development from latent potential';
latentWarning: RpgExpandedDangerWarning id = 'first-hazard' profile = latentProfile ability = latentAbility
    hazardPresent = true approved = true interferenceKnown = true evidence = 'Known impending fall'
    warningText = 'Step back.' detailText = 'The roof is falling.';
historyPower: RpgExpandedPsionicPower id = 'history-power' abilityIds = ['object-history'] powerModifier = -10
    approved = true evidence = 'Permitted historical impressions';
historyAbility: RpgExpandedPsionicObjectHistory power = historyPower approved = true evidence = 'Paid ability';
historyTalent: RpgExpandedPsionicTalent id = 'history-talent' power = historyPower level = 2 approved = true evidence = 'Paid talent';
historyProfile: RpgExpandedProfile iq = 8 traits = [historyAbility,historyTalent];
historySubject: object;
class HistoryTestRequest: RpgExpandedHistoryReading
    profile = historyProfile ability = historyAbility subject = historySubject emotionalImpression = true
    touched = true uninterrupted = true approved = true interferenceKnown = true evidence = 'A marked cup from an argument'
    impressionText = 'Someone argued here.' visionText = 'You see two people arguing over the cup.'
    misleadingText = 'The cup was a peaceful wedding gift.'
;
historyRequest: HistoryTestRequest id = 'cup-reading';
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
        if (code >= 60)
        {
            if (code == 64) historyRequest.terrifying = true;
            if (code == 65) historyRequest.touched = nil;
            if (code == 66) warningInput.forcedRoll = 15;
            if (code == 67) warningInput.forcedRoll = 16;
            if (code == 68) warningInput.forcedRoll = 3;
            if (code == 69) historyRequest.emotionalImpression = nil;
            local request = historyRequest;
            if (code == 70 || code == 71)
            {
                rpgSpendTime(code == 70 ? 86399 : 1);
                request = new HistoryTestRequest(); request.id = 'retry-cup'; warningInput.forcedRoll = 10;
            }
            local value = code == 63 ? request.assess() : request.apply();
            event('test.history-reading'); eventValue(value.status); eventValue(value.reason); eventValue(value.information);
            if (code == 62) throw new RpgError(); return nil;
        }
        if (code >= 40)
        {
            if (code == 44) latentProfile.unspentPoints = 0;
            if (code == 45 || code == 46) latentProfile.traits = [];
            if (code == 46) latentPurchase.newPowerApproved = true;
            if (code == 47) latentProfile.developmentOpen = nil;
            if (code == 48)
            {
                local warning = latentWarning.apply(); event('test.purchased-warning');
                eventValue(warning.status); eventValue(warning.reason); eventValue(warning.warning); return nil;
            }
            local value = code == 41 ? latentPurchase.assess() : latentPurchase.apply();
            event('test.psionic-purchase'); eventValue(value.status); eventValue(value.reason); eventValue(value.points);
            if (code == 42) throw new RpgError(); return nil;
        }
        if (code >= 20)
        {
            if (code == 23) warningObserver.unspentPoints = 0;
            if (code == 24) warningObserver.traits = [warningAbility];
            if (code == 25 || code == 26) warningObserver.traits = [];
            if (code == 26) warningAdvancement.newPowerApproved = true;
            if (code == 27) warningObserver.developmentOpen = nil;
            if (code == 28) warningAdvancement.targetLevel = 5;
            if (code == 29) { warningAdvancement.targetLevel = 5; warningAdvancement.aboveFourApproved = true; }
            local value = code == 21 ? warningAdvancement.assess() : warningAdvancement.apply();
            event('test.psionic-advance'); eventValue(value.status); eventValue(value.reason); eventValue(value.points);
            if (code == 22) throw new RpgError(); return nil;
        }
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
    if (verb == 2244)
    {
        local request = new HistoryTestRequest(); request.id = 'age-preview'; request.ageBand = args[1];
        event('test.history-age'); eventValue(rpgLiteScore(historyProfile,request.context()));
        eventValue(request.assess().status); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2242) { warningInput.code = 60 + args[1]; return vhylAct(2231,args); }
    if (verb == 2243)
    {
        event('test.history-state'); eventValue(historyProfile.psionicHistoryReadings.length());
        eventValue(historyProfile.lastCheck == nil ? 0 : 1); eventValue(historyAbility.creationCost());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2240) { warningInput.code = 40 + args[1]; return vhylAct(2231,args); }
    if (verb == 2241)
    {
        event('test.psionic-purchase-state'); eventValue(holds(latentProfile.traits,latentAbility) ? 1 : 0);
        eventValue(latentProfile.unspentPoints); eventValue(latentProfile.developmentRevision);
        eventValue(latentProfile.psionicAbilityPurchases.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2238) { warningInput.code = 20 + args[1]; return vhylAct(2231,args); }
    if (verb == 2239)
    {
        event('test.psionic-advance-state'); eventValue(warningTalent.level); eventValue(warningObserver.unspentPoints);
        eventValue(warningObserver.developmentRevision); eventValue(warningObserver.psionicTalentAdvancements.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
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
        if (!resistance.active)
        {
            try { resistance.validateResistance(); }
            catch (RpgExpandedError error) { event('test.psionic-resistance-reject'); eventValue(error.reason); }
            return nil;
        }
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
