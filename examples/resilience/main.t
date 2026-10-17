#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-dialogue.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-report.t>
#include <vhyl-rpg-resilience.t>
#include <vhyl-rpg-conflict.t>
#include <vhyl-rpg-progression.t>

gatehouse: Room 'Rain Gatehouse'
    desc
    {
        return gateSay('Rain drums on the gatehouse. Your ankle hurts. A guard blocks the road; a medic waits beside a bench. Try find permit, request passage, treat wounds, rest, or confront guard. Use :plan for choices.');
    }
;
gateGuard: Actor 'road guard' location(gatehouse) vocab = 'guard; road';
gateMedic: Actor 'medic' location(gatehouse) vocab = 'medic';

gateAid: RpgSkill labelId = 'gate.first-aid' attribute = rpgIQ difficulty = 0 defaultPenalty = -4;
gateBrawl: RpgSkill labelId = 'gate.brawling' attribute = rpgDX difficulty = 0 defaultPenalty = -4;
gateTalk: RpgSkill labelId = 'gate.negotiation' attribute = rpgIQ difficulty = 1 defaultPenalty = -5;
gateAidTraining: RpgTraining skill = gateAid points = 2;
gateBrawlTraining: RpgTraining skill = gateBrawl points = 2;
gateTalkTraining: RpgTraining skill = gateTalk points = 2;
gateMedicTraining: RpgTraining skill = gateAid points = 8;
gateNerves: RpgTrait labelId = 'gate.nerves'
    modifierFor(c) { return c.skill == gateBrawl ? -1 : 0; }
;
gatePoise: RpgTrait labelId = 'gate.poise'
    modifierFor(c) { return c.skill == gateTalk ? 1 : 0; }
;
gateHero: RpgProfile actor = player dx = 11 iq = 11 energy = 6
    skills = [gateAidTraining, gateBrawlTraining, gateTalkTraining]
    traits = [gateNerves] resilience = gateHeroBody;
gateHeroBody: RpgBody profile = gateHero injury = 3 aidRemaining = 3;
gateGuardProfile: RpgProfile actor = gateGuard will = 11 resilience = gateGuardBody;
gateGuardBody: RpgBody profile = gateGuardProfile;
gateMedicProfile: RpgProfile actor = gateMedic iq = 12 skills = [gateMedicTraining];
modify player rpgProfile = gateHero;
modify gateGuard rpgProfile = gateGuardProfile;
modify gateMedic rpgProfile = gateMedicProfile;
gateState: object permit = nil passage = nil refuses = nil;

gatePassage: RpgChallenge id = 'gate.passage';
gateMood: RpgDisposition profile = gateGuardProfile
    permits(actor, approach) { return gateState.refuses ? 'gate.unacceptable' : nil; }
;
gateParley: RpgSocialApproach id = 'parley' challenge = gatePassage
    disposition = gateMood skill = gateTalk timeCost = 60
    assessmentDisclosure = gateSocialDisclosure rollDisclosure = gateSocialDisclosure
    modifierFor(c) { return gateState.permit ? 2 : 0; }
    apply(c, result)
    {
        inherited(c, result);
        if (result.achieved) gateOpen();
        return nil;
    }
;
gateSocialDisclosure: RpgDisclosure visible = true showAbility = true
    showCalculation = true showCosts = true showAvailability = true
    showOutcome = true showDice = true estimateLabelId = 'gate.uncertain';
gateParleySlot: RpgAttempt profile = gateHero approach = gateParley;
gateTreatment: RpgTreatment skill = gateAid charges = 2;
gateHeroFighter: RpgCombatant profile = gateHero skill = gateBrawl;
gateGuardFighter: RpgCombatant profile = gateGuardProfile armor = 1 damageBonus = -3;
gateConflict: RpgConflict id = 'gate.encounter' protagonist = gateHeroFighter
    opposition = gateGuardFighter maxExchanges = 6 discloseRolls = true
    available() { return gateState.passage ? 'gate.no-reason-to-fight' : nil; }
    ended(result)
    {
        rpgPublishProgress(rpgAwardMilestone(gateHero, gateSurvivalAward));
        gateHero.developmentOpen = true;
        if (result.outcome == 'won') gateOpen();
        gateSay(result.outcome == 'defeated'
            ? 'You cannot continue. The guard lowers their hands and calls the medic. Accept help to continue.'
            : 'The confrontation ends. You can rest, develop your abilities, or show your permit.');
        return nil;
    }
;

gatePassageAward: RpgMilestone id = 'gate.safe-passage' points = 6
    available(profile) { return gateState.passage ? nil : 'gate.no-passage'; }
    apply(profile) { gateUnlock(); return nil; }
;
gateSurvivalAward: RpgMilestone id = 'gate.encounter-ended' points = 6
    available(profile) { return gateConflict.finished ? nil : 'gate.encounter-active'; }
    apply(profile) { gateUnlock(); return nil; }
;
gatePassageReceipt: RpgAward profile = gateHero milestone = gatePassageAward;
gateSurvivalReceipt: RpgAward profile = gateHero milestone = gateSurvivalAward;
gateStudyAid: RpgDevelopment id = 'gate.study-aid' profile = gateHero
    training = gateAidTraining target = 4;
gatePractice: RpgDevelopment id = 'gate.practice' profile = gateHero
    training = gateBrawlTraining target = 4;
gateResolve: RpgDevelopment id = 'gate.resolve' profile = gateHero
    kind = 'attribute' attribute = rpgWill target = 12;
gateLearnPoise: RpgDevelopment id = 'gate.learn-poise' profile = gateHero
    kind = 'trait' trait = gatePoise cost = 3 reopens = [gatePassage];
gateOvercomeNerves: RpgDevelopment id = 'gate.overcome-nerves' profile = gateHero
    kind = 'remove-trait' trait = gateNerves cost = 3;

gateUnlock()
{
    foreach (local offer in [gateStudyAid, gatePractice, gateResolve, gateLearnPoise, gateOvercomeNerves])
        offer.unlocked = true;
    return nil;
}
gateOpen()
{
    gateState.passage = true; gatePassage.completed = true;
    gateHero.developmentOpen = true;
    if (gateConflict.active)
    {
        local value = new RpgConflictResult(); value.conflict = gateConflict; value.status = 'resolved';
        rpgFinishConflict(value, 'truce'); rpgPublishConflict(value);
    }
    rpgPublishProgress(rpgAwardMilestone(gateHero, gatePassageAward));
    return nil;
}
gateSay(text)
{
    event('survey.text'); eventValue(text); "<<text>>\n"; return nil;
}

/* The parser and choices call this same committed adapter. Read-only codes
 * are handled by act() separately, outside the gameplay turn cycle. */
gateDo(code)
{
    if (here() != gatehouse) return gateSay('Return to the gatehouse first.');
    if (code == 410)
    {
        if (gateConflict.active) return gateSay('The medic cannot intervene during the confrontation.');
        if (gateHeroBody.dead) return gateSay('This injury is beyond the clinic.');
        if (gateHeroBody.unconscious)
        {
            gateHeroBody.injury = gateHero.maxHP - 1; gateHeroBody.aidRemaining = 0;
            gateHeroBody.unconscious = nil; gateHeroBody.stunned = nil;
            gateHero.energy = gateHero.maxEnergy; rpgSpendTime(86400);
            gateSay('After a day in the clinic you wake, badly hurt but able to continue.');
        }
        else gateSay('The medic is ready to treat your wounds.');
    }
    else if (code == 400 || code == 401 || code == 402)
    {
        if (gateHeroBody.unconscious || gateHeroBody.dead || gateHeroBody.stunned)
            return gateSay('You need help or recovery before pursuing passage.');
        if (code == 400)
        {
            if (!gateState.permit) { gateState.permit = true; gatePassage.advance(); }
            gateSay('You find your stamped travel permit tucked beneath the bench.');
            gateHeroBody.endAction();
        }
        else if (code == 401)
        {
            if (!gateState.permit) return gateSay('Find your permit first.');
            gateOpen(); gateSay('The guard accepts your permit and opens the road.');
            gateHeroBody.endAction();
        }
        else
        {
            local result = rpgResolve(gateHero, gateParley);
            rpgPublish(result); rpgPublishRoll(result, nil);
            gateSay(result.status == 'reused' ? 'The guard remembers your unchanged request.'
                : result.status == 'complete' ? 'Passage is already arranged.'
                : result.achieved ? 'The guard agrees to let you through.' : 'The guard refuses this request.');
        }
    }
    else if (code == 403 || code == 404 || code == 411)
    {
        if (gateConflict.active) return gateSay('Finish the confrontation before treatment or rest.');
        if (code == 403)
        {
            local result = rpgTreat(gateMedicProfile, gateHero, gateTreatment);
            gateSay(result.injury > 0 ? 'Treatment goes wrong; your injuries worsen.'
                : result.status == 'resolved' ? 'The medic treats your wounds with a fresh dressing.'
                : 'There is no available treatment for these wounds now.');
        }
        else
        {
            local result = rpgRest(gateHero, code == 411 ? 86400 : 600);
            if (result.status == 'resolved')
            {
                gateHero.developmentOpen = true;
                gateSay(code == 411 ? 'A quiet day passes in the gatehouse clinic.' : 'You rest quietly for ten minutes.');
            }
            else gateSay('Rest cannot restore this condition.');
        }
    }
    else if (code == 413 && !gateConflict.active)
    {
        local result = rpgRecoverStun(gateHero);
        gateSay(result.status == 'resolved' ? 'You pause and try to shake off the stun.' : 'There is no stun to recover from now.');
    }
    else if (code >= 406 && code <= 409 || code == 412 || code == 413)
    {
        local result = code == 406 ? rpgBeginConflict(gateConflict)
            : rpgConflictStep(gateConflict, code == 407 ? 'attack' : code == 408 ? 'defend'
                : code == 409 ? 'escape' : code == 412 ? 'surrender' : 'recover');
        if (gateConflict.active) gateHero.developmentOpen = nil;
        rpgPublishConflict(result);
        gateSay(result.status == 'blocked' ? 'That maneuver is unavailable; try recover, surrender, or accept help.'
            : gateConflict.active ? 'The confrontation continues. Attack, defend, escape, recover, or surrender.'
            : 'The confrontation is over.');
    }
    else if (code >= 414 && code <= 418)
    {
        if (gateHeroBody.unconscious || gateHeroBody.dead || gateHeroBody.stunned)
            return gateSay('Recover before beginning development practice.');
        local offer = [gateStudyAid, gatePractice, gateResolve, gateLearnPoise, gateOvercomeNerves][code - 413];
        local result = rpgDevelop(offer); rpgPublishProgress(result);
        if (result.status == 'resolved') gateHeroBody.endAction();
        gateSay(result.status == 'resolved' ? 'You practise with the medic and commit the improvement.'
            : result.status == 'reused' ? 'You have already attained that improvement.'
            : 'That development needs an unlocked opportunity, sufficient points, and quiet downtime.');
    }
    rpgPublishBody(gateHero); return nil;
}

class GateAction: Action
    code = 0
    exec(c) { return gateDo(self.code); }
;
gateFind: GateAction code = 400;
gateShow: GateAction code = 401;
gateRequest: GateAction code = 402;
gateTreatAction: GateAction code = 403;
gateRestAction: GateAction code = 404;
gateConfront: GateAction code = 406;
gateAttack: GateAction code = 407;
gateDefend: GateAction code = 408;
gateEscape: GateAction code = 409;
gateHelp: GateAction code = 410;
gateDay: GateAction code = 411;
gateSurrender: GateAction code = 412;
gateRecover: GateAction code = 413;
gateTrainAid: GateAction code = 414;
gateTrainBrawl: GateAction code = 415;
gateTrainWill: GateAction code = 416;
gateTrainPoise: GateAction code = 417;
gateTrainNerves: GateAction code = 418;

vGateFind: Verb code = 400 action = gateFind label = 'gate-find';
vGateShow: Verb code = 401 action = gateShow label = 'gate-show';
vGateRequest: Verb code = 402 action = gateRequest label = 'gate-request';
vGateTreat: Verb code = 403 action = gateTreatAction label = 'gate-treat';
vGateRest: Verb code = 404 action = gateRestAction label = 'gate-rest';
vGateConfront: Verb code = 406 action = gateConfront label = 'gate-confront';
vGateAttack: Verb code = 407 action = gateAttack label = 'gate-attack';
vGateDefend: Verb code = 408 action = gateDefend label = 'gate-defend';
vGateEscape: Verb code = 409 action = gateEscape label = 'gate-escape';
vGateHelp: Verb code = 410 action = gateHelp label = 'gate-help';
vGateDay: Verb code = 411 action = gateDay label = 'gate-day';
vGateSurrender: Verb code = 412 action = gateSurrender label = 'gate-surrender';
vGateRecover: Verb code = 413 action = gateRecover label = 'gate-recover';
vGateTrainAid: Verb code = 414 action = gateTrainAid label = 'gate-train-aid';
vGateTrainBrawl: Verb code = 415 action = gateTrainBrawl label = 'gate-train-brawl';
vGateTrainWill: Verb code = 416 action = gateTrainWill label = 'gate-train-will';
vGateTrainPoise: Verb code = 417 action = gateTrainPoise label = 'gate-train-poise';
vGateTrainNerves: Verb code = 418 action = gateTrainNerves label = 'gate-train-nerves';

grammar command(gateFindCmd): 'find' 'permit' : Command action = gateFind;
grammar command(gateShowCmd): 'show' 'permit' : Command action = gateShow;
grammar command(gateRequestCmd): 'request' 'passage' : Command action = gateRequest;
grammar command(gateTreatCmd): 'treat' 'wounds' : Command action = gateTreatAction;
grammar command(gateRestCmd): 'rest' : Command action = gateRestAction;
grammar command(gateDayCmd): 'rest' 'day' : Command action = gateDay;
grammar command(gateConfrontCmd): 'confront' 'guard' : Command action = gateConfront;
grammar command(gateAttackCmd): 'attack' : Command action = gateAttack;
grammar command(gateDefendCmd): 'defend' : Command action = gateDefend;
grammar command(gateEscapeCmd): 'escape' : Command action = gateEscape;
grammar command(gateHelpCmd): 'accept' 'help' : Command action = gateHelp;
grammar command(gateSurrenderCmd): 'surrender' : Command action = gateSurrender;
grammar command(gateRecoverCmd): 'recover' : Command action = gateRecover;
grammar command(gateAidCmd): 'train' 'aid' : Command action = gateTrainAid;
grammar command(gateBrawlCmd): 'train' 'brawl' : Command action = gateTrainBrawl;
grammar command(gateWillCmd): 'train' 'resolve' : Command action = gateTrainWill;
grammar command(gatePoiseCmd): 'learn' 'poise' : Command action = gateTrainPoise;
grammar command(gateNervesCmd): 'overcome' 'nerves' : Command action = gateTrainNerves;

class GateChoice: DialogueChoice
    code = 0
    available(c)
    {
        if (here() != gatehouse) return nil;
        if (self.code == 410) return gateHeroBody.unconscious && !gateConflict.active;
        if (self.code == 403) return !gateConflict.active && gateHeroBody.aidRemaining > 0 && gateTreatment.charges > 0;
        if (self.code == 404 || self.code == 411) return !gateConflict.active;
        if (gateHeroBody.unconscious || gateHeroBody.dead) return nil;
        if (self.code == 413) return gateHeroBody.stunned;
        if (self.code >= 407 && self.code <= 409 || self.code == 412) return gateConflict.active;
        if (gateHeroBody.stunned) return nil;
        if (self.code == 406) return !gateConflict.active && !gateConflict.finished && !gateState.passage;
        if (self.code == 400) return !gateState.permit && !gateState.passage;
        if (self.code == 401) return gateState.permit && !gateState.passage;
        if (self.code == 402) return !gatePassage.completed;
        if (self.code >= 414 && self.code <= 418)
        {
            local offer = [gateStudyAid, gatePractice, gateResolve, gateLearnPoise, gateOvercomeNerves][self.code - 413];
            return rpgAssessDevelopment(offer).status == 'ready';
        }
        return nil;
    }
    selected(c) { return gateDo(self.code); }
;
gateFindChoice: GateChoice id = 'find' code = 400 labelId = 'gate.find';
gateShowChoice: GateChoice id = 'show' code = 401 labelId = 'gate.show';
gateTalkChoice: GateChoice id = 'talk' code = 402 labelId = 'gate.talk';
gateTreatChoice: GateChoice id = 'treat' code = 403 labelId = 'gate.treat';
gateRestChoice: GateChoice id = 'rest' code = 404 labelId = 'gate.rest';
gateConfrontChoice: GateChoice id = 'confront' code = 406 labelId = 'gate.confront';
gateAttackChoice: GateChoice id = 'attack' code = 407 labelId = 'gate.attack';
gateEscapeChoice: GateChoice id = 'escape' code = 409 labelId = 'gate.escape';
gateSurrenderChoice: GateChoice id = 'surrender' code = 412 labelId = 'gate.surrender';
gateHelpChoice: GateChoice id = 'help' code = 410 labelId = 'gate.help';
gateDevelopChoice: GateChoice id = 'develop' code = 414 labelId = 'gate.develop';
gateDefendChoice: GateChoice id = 'defend' code = 408 labelId = 'gate.defend';
gateRecoverChoice: GateChoice id = 'recover' code = 413 labelId = 'gate.recover';
gateDayChoice: GateChoice id = 'day' code = 411 labelId = 'gate.day';
gatePracticeChoice: GateChoice id = 'practice' code = 415 labelId = 'gate.practice';
gateResolveChoice: GateChoice id = 'resolve' code = 416 labelId = 'gate.resolve';
gatePoiseChoice: GateChoice id = 'poise' code = 417 labelId = 'gate.poise';
gateNervesChoice: GateChoice id = 'nerves' code = 418 labelId = 'gate.nerves';
gatePlan: Conversation id = 'gate.plan' target = gateMedic
    choices = [gateFindChoice, gateShowChoice, gateTalkChoice, gateTreatChoice, gateRestChoice,
        gateConfrontChoice, gateAttackChoice, gateEscapeChoice, gateSurrenderChoice, gateHelpChoice,
        gateDefendChoice, gateRecoverChoice, gateDayChoice, gateDevelopChoice, gatePracticeChoice,
        gateResolveChoice, gatePoiseChoice, gateNervesChoice]
;
gateFindLabel: Message id = 'gate.find' text = 'Find your travel permit';
gateShowLabel: Message id = 'gate.show' text = 'Show the permit';
gateTalkLabel: Message id = 'gate.talk' text = 'Negotiate passage';
gateTreatLabel: Message id = 'gate.treat' text = 'Ask the medic to treat your wounds';
gateRestLabel: Message id = 'gate.rest' text = 'Rest for ten minutes';
gateConfrontLabel: Message id = 'gate.confront' text = 'Confront the guard';
gateAttackLabel: Message id = 'gate.attack' text = 'Attack during the confrontation';
gateEscapeLabel: Message id = 'gate.escape' text = 'Escape the confrontation';
gateSurrenderLabel: Message id = 'gate.surrender' text = 'Surrender without another attack';
gateHelpLabel: Message id = 'gate.help' text = 'Accept help after incapacitation';
gateDevelopLabel: Message id = 'gate.develop' text = 'Study first aid at a quiet pause (two points)';
gateDefendLabel: Message id = 'gate.defend' text = 'Concentrate on defense';
gateRecoverLabel: Message id = 'gate.recover' text = 'Recover from stun';
gateDayLabel: Message id = 'gate.day' text = 'Spend a day resting at the clinic';
gatePracticeLabel: Message id = 'gate.practice' text = 'Practise brawling (two points)';
gateResolveLabel: Message id = 'gate.resolve' text = 'Strengthen resolve (five points)';
gatePoiseLabel: Message id = 'gate.poise' text = 'Learn composure (three points)';
gateNervesLabel: Message id = 'gate.nerves' text = 'Overcome nerves (three points)';

modify gameMain initialRoom = gatehouse;
startup() { rpgRandom.seed(27); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
#ifndef RPG_GATE_CUSTOM_ACT
act(verb, args) { return gateAct(verb, args); }
#endif
gateAct(verb, args)
{
    if (verb == 405)
    {
        rpgPublishBody(gateHero);
        rpgPublishAssessment(rpgAssess(gateHero, gateParley), nil);
        foreach (local offer in [gateStudyAid, gatePractice, gateResolve, gateLearnPoise, gateOvercomeNerves])
            rpgPublishProgress(rpgAssessDevelopment(offer));
        return nil;
    }
    return vhylAct(verb, args);
}
