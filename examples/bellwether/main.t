#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-dialogue.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded-character-social.t>

/* Original integration vignette; these characters and facts are not campaign canon. */
registry: Room 'Town Registry'
    desc { return registrySay('Rain taps the registry windows. A missing ledger may explain the late relief deliveries. Try create investigator, ask ledger, or status.'); }
;
registryClerk: Actor 'clerk' location(registry) vocab = 'clerk registrar';
registryRules: RpgExpandedRules;
recordsSkill: RpgExpandedSkill id = 'records-research' attribute = rpgIQ difficulty = 1;
interviewSkill: RpgExpandedSkill id = 'local-interviews' attribute = rpgIQ difficulty = 1;
investigatorTemplate: RpgExpandedTemplate iq = 11 willAdjustment = 1 pointBudget = 40
    skillRows = [[recordsSkill,2],[interviewSkill,2]];
registryState: object investigator = nil recognition = nil encounter = nil;
clerkProfile: RpgExpandedProfile rules = registryRules actor = registryClerk knowledge = clerkKnowledge;
clerkKnowledge: RpgExpandedKnowledge owner = clerkProfile beliefs = ['ledger-moved','cart-departure','spare-key'];
registrySay(text) { event('survey.text'); eventValue(text); return nil; }
registryStatus()
{
    local profile = registryState.investigator;
    if (profile == nil) return registrySay('Create an investigator to begin.');
    local heard = 0;
    foreach (local receipt in profile.knowledge.received) heard += receipt[3].length();
    registrySay('Character cost: <<rpgExpandedCharacterCost(profile,nil)>> / <<profile.pointBudget>>. IQ <<profile.iq>>, Will <<profile.will>>. Records <<profile.skillScore(recordsSkill)>>, interviews <<profile.skillScore(interviewSkill)>>.');
    registrySay('Statements heard: <<heard>>. Elapsed seconds: <<rpgLedger.seconds>>.');
    event('bellwether.state'); eventValue(rpgExpandedCharacterCost(profile,nil)); eventValue(profile.will);
    eventValue(profile.skillScore(recordsSkill)); eventValue(heard); eventValue(rpgLedger.seconds); return nil;
}
registryCreate()
{
    if (registryState.investigator != nil) return registryStatus();
    local profile = investigatorTemplate.create(registryRules); profile.actor = player;
    local reputation = new RpgExpandedReputation(); reputation.id = 'careful-recordkeeper'; reputation.owner = profile;
    reputation.details = 'Known among local recordkeepers for returning borrowed documents intact.';
    reputation.facets = [['recordkeepers',2,'large']]; profile.contributions = [reputation];
    local knowledge = new RpgExpandedKnowledge(); knowledge.owner = profile; profile.knowledge = knowledge;
    rpgExpandedValidateCharacter(profile); profile.creationComplete = true;
    local recognition = new RpgExpandedReputationRecognition(); recognition.reputation = reputation;
    recognition.audience = registryClerk; recognition.facet = 'recordkeepers'; recognition.inArea = true; recognition.identityExposed = true;
    local encounter = new RpgExpandedReactionEncounter(); encounter.id = 'ledger-enquiry'; encounter.subject = profile;
    encounter.audience = registryClerk;
    // The clerk remains civil in this authored scene, even after an unfavorable roll.
    encounter.worstBand = 3; profile.reactionEncounters = [encounter];
    registryState.investigator = profile; registryState.recognition = recognition; registryState.encounter = encounter;
    registrySay('Your investigator has a modest reputation among local recordkeepers.'); return registryStatus();
}
registryAsk()
{
    local profile = registryState.investigator;
    if (profile == nil) return registrySay('Create an investigator first.');
    if (registryState.encounter.history.length() > 0)
        return registrySay('The clerk has already answered this approach. Review what you heard before deciding on a genuinely different question.');
    rpgExpandedValidateCharacter(profile); rpgInteger(rpgLedger.seconds,0,2147483587);
    registryState.recognition.resolve();
    local attempt = new RpgExpandedReactionAttempt(); attempt.encounter = registryState.encounter;
    attempt.approach = 'polite-ledger-enquiry'; attempt.modifier = rpgExpandedReputationModifier([registryState.recognition]);
    local reaction = attempt.resolve();
    local response = new RpgExpandedInformationReaction(); response.band = reaction.band; response.complexity = 0;
    response.adverseChoice = 'partial';
    local delivery = new RpgExpandedInformationDelivery(); delivery.id = 'clerk-ledger-answer'; delivery.provider = clerkProfile;
    delivery.recipient = profile; delivery.reaction = response; delivery.available = true;
    delivery.requested = ['ledger-moved','cart-departure']; delivery.partial = ['ledger-moved']; delivery.related = ['spare-key'];
    local result = delivery.deliver();
    if (result.status != 'resolved') rpgExpandedReject('registry-answer-unavailable');
    rpgSpendTime(60);
    foreach (local statement in result.statements)
    {
        if (statement == 'ledger-moved') registrySay('The clerk says the missing ledger was moved to the riverside storehouse.');
        if (statement == 'cart-departure') registrySay('A relief cart left that storehouse before dawn, according to the clerk.');
        if (statement == 'spare-key') registrySay('The clerk volunteers that the caretaker keeps a spare storehouse key.');
    }
    // Publish authored speech and received information, never the private attitude or dice.
    return registryStatus();
}
registryDo(code)
{
    if (code == 1301) return registryCreate();
    if (code == 1302) return registryAsk();
    return registryStatus();
}
class RegistryAction: Action code = 1300 exec(context) { return registryDo(self.code); };
registryStatusAction: RegistryAction code = 1300;
registryCreateAction: RegistryAction code = 1301;
registryAskAction: RegistryAction code = 1302;
registryStatusVerb: Verb code = 1300 action = registryStatusAction label = 'registry-status';
registryCreateVerb: Verb code = 1301 action = registryCreateAction label = 'registry-create';
registryAskVerb: Verb code = 1302 action = registryAskAction label = 'registry-ask';
grammar command(registryStatusCmd): 'status' : Command action = registryStatusAction;
grammar command(registryCreateCmd): 'create' 'investigator' : Command action = registryCreateAction;
grammar command(registryAskCmd): 'ask' 'ledger' : Command action = registryAskAction;
registryPlan: Conversation id = 'registry-plan' target = registryClerk choices = [registryCreateChoice,registryAskChoice];
class RegistryChoice: DialogueChoice code = 1300 selected(context) { return registryDo(self.code); };
registryCreateChoice: RegistryChoice id = 'create-investigator' labelId = 'registry.create' code = 1301;
registryAskChoice: RegistryChoice id = 'ask-ledger' labelId = 'registry.ask' code = 1302;
registryCreateLabel: Message id = 'registry.create' text = 'Create an investigator';
registryAskLabel: Message id = 'registry.ask' text = 'Ask about the missing ledger';
modify gameMain initialRoom = registry;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args) { if (verb == 1300) return registryStatus(); return vhylAct(verb,args); }
