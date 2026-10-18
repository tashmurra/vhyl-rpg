#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded-character-social.t>
fixtureRoom: Room 'Registry';
fixtureRules: RpgExpandedRules;
fixtureHero: RpgExpandedProfile rules = fixtureRules iq = 12 hpAdjustment = 1 pointBudget = 100
    skills = [fixtureTraining] contributions = [fixtureReputation,fixtureStanding]
    reactionEncounters = [fixtureEncounter] knowledge = fixtureKnowledge money = 10 loyalties = [fixtureLoyalty];
fixtureSkill: RpgExpandedSkill id = 'hard-records' attribute = rpgIQ difficulty = 3;
fixtureTraining: RpgExpandedTraining skill = fixtureSkill points = 4;
fixtureStanding: RpgExpandedStatus id = 'local-status' owner = fixtureHero culture = 'town' level = 1;
fixtureReputation: RpgExpandedReputation id = 'local-reputation' owner = fixtureHero details = 'Reliable records'
    facets = [['recordkeepers',2,'large']] frequency = 'sometimes';
fixtureRecognition: RpgExpandedReputationRecognition reputation = fixtureReputation audience = 'clerk'
    facet = 'recordkeepers' inArea = true identityExposed = true;
fixtureEncounter: RpgExpandedReactionEncounter id = 'clerk-enquiry' subject = fixtureHero audience = 'clerk';
fixtureAttempt: RpgExpandedReactionAttempt encounter = fixtureEncounter approach = 'polite-question';
fixtureKnowledge: RpgExpandedKnowledge owner = fixtureHero;
fixtureProvider: RpgExpandedProfile rules = fixtureRules knowledge = fixtureProviderKnowledge;
fixtureProviderKnowledge: RpgExpandedKnowledge owner = fixtureProvider beliefs = ['first-fact','second-fact'];
fixtureResponse: RpgExpandedInformationReaction band = 2 adverseChoice = 'payment';
fixtureDelivery: RpgExpandedInformationDelivery id = 'paid-answer' provider = fixtureProvider recipient = fixtureHero
    reaction = fixtureResponse requested = ['first-fact','second-fact'] partial = ['first-fact']
    available = true price = 5 paymentApproved = true;
fixtureLoyalty: RpgExpandedLoyalty id = 'service' subject = fixtureHero employer = 'archive' preset = 12;
fixtureLoyaltyCheck: RpgExpandedLoyaltyCheck loyalty = fixtureLoyalty incident = 'trust-record' necessary = true;
fixtureInput: object code = 0;
class CharacterSocialAction: Action
    exec(context)
    {
        local code = fixtureInput.code;
        if (code == 1 || code == 2 || code == 3)
        {
            if (code == 3) fixtureReputation.frequency = 'occasionally';
            fixtureRecognition.resolve(); fixtureAttempt.modifier = rpgExpandedReputationModifier([fixtureRecognition]);
            local value = fixtureAttempt.resolve(); event('test.private-reaction'); eventValue(value.status); eventValue(value.band);
            if (code == 2) throw new RpgError();
        }
        if (code == 4 || code == 5)
        {
            local value = fixtureDelivery.deliver(); event('test.paid-answer'); eventValue(value.status); eventValue(value.money);
            if (code == 5) throw new RpgError();
        }
        if (code == 6 || code == 7)
        {
            fixtureLoyalty.initialize(); local value = fixtureLoyaltyCheck.resolve();
            event('test.private-loyalty'); eventValue(value.status); eventValue(value.loyal ? 1 : 0);
            if (code == 7) throw new RpgError();
        }
        return nil;
    }
;
fixtureAction: CharacterSocialAction;
fixtureVerb: Verb code = 1400 action = fixtureAction label = 'character-social-fixture';
modify gameMain initialRoom = fixtureRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1400) { fixtureInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1450)
    {
        event('test.character-social-state'); eventValue(fixtureReputation.recognitions.length());
        eventValue(fixtureEncounter.history.length()); eventValue(fixtureHero.money); eventValue(fixtureProvider.money);
        eventValue(fixtureKnowledge.received.length()); eventValue(fixtureLoyalty.incidents.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 1451)
    {
        local value = fixtureAttempt.assess(); event('test.private-preview'); eventValue(value.status);
        eventValue(value.band); eventValue(value.total); eventValue(value.check); return nil;
    }
    if (verb == 1452)
    {
        rpgExpandedValidateCharacter(fixtureHero); event('test.character-cost');
        eventValue(rpgExpandedCharacterCost(fixtureHero,nil)); eventValue(fixtureHero.will);
        eventValue(fixtureHero.skillScore(fixtureSkill)); return nil;
    }
    if (verb == 1453)
    {
        event('test.skill-table'); eventValue(rpgExpandedSkillLevel(12,args[1],args[2],args[3] == 1)); return nil;
    }
    if (verb == 1454)
    {
        local p = new RpgExpandedProfile(); p.rules = fixtureRules; p.iq = 12;
        local a = new RpgExpandedSkill(); a.id = 'a'; a.attribute = rpgIQ; a.difficulty = 0;
        local b = new RpgExpandedSkill(); b.id = 'b'; b.attribute = rpgIQ; b.defaults = [[a,-2]];
        local c = new RpgExpandedSkill(); c.id = 'c'; c.attribute = rpgIQ; c.defaults = [[b,-2]];
        local t = new RpgExpandedTraining(); t.skill = a; t.points = 4; p.skills = [t];
        event('test.skill-defaults'); eventValue(p.skillScore(a)); eventValue(p.skillScore(b)); eventValue(p.skillScore(c));
        local technique = new RpgExpandedTechnique(); technique.id = 'technique'; technique.owner = p;
        technique.skill = a; technique.penalty = -2; technique.points = 1; p.contributions = [technique];
        eventValue(technique.score()); return nil;
    }
    if (verb == 1455)
    {
        local p = new RpgExpandedProfile(); p.rules = fixtureRules;
        if (args[1] == 1) p.hpAdjustment = 4;
        if (args[1] == 2)
        {
            local language = new RpgLiteLanguage(); language.id = 'native'; language.native = true;
            p.languages = [language,language];
        }
        if (args[1] == 3)
        {
            local language = new RpgLiteLanguage(); language.id = 'native'; language.native = true; language.spoken = 2;
            p.languages = [language];
        }
        if (args[1] == 4) p.traits = [rpgLiteMakeTrait('luck',1,nil),rpgLiteMakeTrait('unluckiness',1,nil)];
        if (args[1] == 5) { p.iq = 12; p.pointBudget = 10; }
        event('test.invalid-character');
        try { rpgExpandedValidateCharacter(p); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1456)
    {
        local template = new RpgExpandedTemplate(); template.skillRows = [[fixtureSkill,4]];
        local a = template.create(fixtureRules); local b = template.create(fixtureRules);
        a.skills[1].points = 8; event('test.template-ownership');
        eventValue(a.skills[1].points); eventValue(b.skills[1].points);
        eventValue(a.skills[1] != b.skills[1] ? 1 : 0); return nil;
    }
    if (verb == 1457)
    {
        local skill = args[1] == 1 ? new RpgSkill() : args[1] == 2 ? new RpgLiteSkill() : new RpgExpandedSkill();
        skill.difficulty = args[1] == 4 ? 4 : 3;
        if (args[1] == 5) skill.attribute = nil;
        if (args[1] == 6) skill.defaultPenalty = 1;
        event('test.skill-definition');
        try { rpgExpandedValidateSkill(skill); eventValue('accepted'); }
        catch (RpgError error) { eventValue('rejected'); }
        return nil;
    }
    return vhylAct(verb,args);
}
