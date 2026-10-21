#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-dialogue.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>

vault: Room 'Echo Vault'
    desc { return vaultSay('The archive clock has stopped, but its reflection still ticks. Your guide waits by the stairs. Try call guide, face reflection, breathe, read inscription, or status.'); }
;
vaultGuide: Actor 'guide' location(vault) vocab = 'guide';
vaultRules: RpgExpandedRules;
vaultProfile: RpgExpandedProfile actor = player rules = vaultRules;
modify player rpgProfile = vaultProfile;
vaultOccurrence: object;
vaultContext: RpgExpandedFearContext profile = vaultProfile approved = true isolated = true
    evidence = 'An impossible moving reflection in an otherwise motionless clock';
vaultEvent: RpgExpandedFearEvent id = 'clock-reflection' occurrence = vaultOccurrence context = vaultContext;
vaultDecision: RpgExpandedFearAdjudication id = 'confused-by-reflection' entry = vaultEvent mode = 'replace' row = 4
    reason = 'confusion' approved = true evidence = 'This authored harmless illusion causes a moment of confusion rather than physical or lasting consequences';
vaultStun: RpgExpandedFearStun id = 'clock-reflection' context = vaultContext tableTotal = 4 approved = true
    evidence = 'The reflection briefly disrupts attention';
vaultState: object inscriptionRead = nil;
vaultSay(text) { event('survey.text'); eventValue(text); return nil; }
vaultStatus()
{
    vaultSay('Guide nearby: <<vaultContext.isolated ? 'no' : 'yes'>>. Reflection faced: <<vaultEvent.result == nil ? 'no' : 'yes'>>. Shaken attention: <<vaultProfile.mentalStun ? 'yes' : 'no'>>. Inscription read: <<vaultState.inscriptionRead ? 'yes' : 'no'>>.');
    event('vault.state'); eventValue(vaultEvent.result == nil ? 0 : 1); eventValue(vaultProfile.mentalStun ? 1 : 0);
    eventValue(vaultState.inscriptionRead ? 1 : 0); eventValue(rpgLedger.seconds); return nil;
}
class VaultFaceAction: RpgExpandedFearAction
    entry = vaultEvent
    perform(actor)
    {
        local value = inherited(actor); if (value.status != 'resolved') return value;
        if (vaultEvent.result.row != nil)
        {
            if (vaultEvent.consequence == nil && vaultDecision.apply().status != 'resolved') rpgExpandedReject('vault-adjudication');
            local consequence = vaultEvent.applyConsequence(vaultStun);
            if (!holds(['resolved','reused'],consequence.status)) rpgExpandedReject('vault-consequence');
            vaultSay(vaultProfile.mentalStun ? 'For a moment you cannot look away from the ticking reflection. Breathe before continuing.' : 'You remember the moment of confusion, but it has passed.');
        }
        else vaultSay('You keep your composure. The moving hands point toward letters scratched beneath the clock.');
        return value;
    }
;
vaultFaceAction: VaultFaceAction;
vaultDo(code,actor)
{
    if (actor == nil || actor.rpgProfile != vaultProfile) rpgExpandedReject('vault-player-required');
    if (code == 1400) return vaultStatus();
    if (code == 1401)
    {
        if (vaultEvent.result != nil) return vaultSay('The encounter is already recorded; calling the guide now cannot change that check.');
        vaultContext.isolated = nil; return vaultSay('Your guide stands beside you. You are no longer facing the reflection alone.');
    }
    if (code == 1403) { rpgSpendTime(1); return vaultSay('You take a quiet breath.'); }
    if (code == 1404)
    {
        if (vaultState.inscriptionRead) return vaultSay('You already know the answer: the archive key is beneath the stair.');
        if (vaultEvent.result == nil) return vaultSay('You must face the reflection to see where its hands point.');
        local gate = new RpgExpandedActionGate(); gate.id = 'read-vault-inscription'; gate.profile = vaultProfile;
        gate.evidence = 'Read the plainly visible letters after facing the reflection';
        local permission = gate.apply();
        if (permission.status != 'resolved' || !permission.allowed) return vaultSay('You cannot focus on the letters yet.');
        rpgSpendTime(1); vaultState.inscriptionRead = true;
        return vaultSay('The letters read: Beneath the stair, where the last light falls. You have found the archive key.');
    }
    rpgExpandedReject('vault-action');
}
class VaultAction: Action code = 1400 exec(context) { return vaultDo(self.code,context.actor); };
vaultStatusAction: VaultAction code = 1400;
vaultGuideAction: VaultAction code = 1401;
vaultBreatheAction: VaultAction code = 1403;
vaultReadAction: VaultAction code = 1404;
vaultStatusVerb: Verb code = 1400 action = vaultStatusAction label = 'vault-status';
vaultGuideVerb: Verb code = 1401 action = vaultGuideAction label = 'call-guide';
vaultFaceVerb: Verb code = 1402 action = vaultFaceAction label = 'face-reflection';
vaultBreatheVerb: Verb code = 1403 action = vaultBreatheAction label = 'breathe';
vaultReadVerb: Verb code = 1404 action = vaultReadAction label = 'read-inscription';
grammar command(vaultStatusCmd): 'status' : Command action = vaultStatusAction;
grammar command(vaultGuideCmd): 'call' 'guide' : Command action = vaultGuideAction;
grammar command(vaultFaceCmd): 'face' 'reflection' : Command action = vaultFaceAction;
grammar command(vaultBreatheCmd): 'breathe' : Command action = vaultBreatheAction;
grammar command(vaultReadCmd): 'read' 'inscription' : Command action = vaultReadAction;
vaultPlan: Conversation id = 'vault-plan' target = vaultGuide choices = [vaultCallChoice,vaultFaceChoice,vaultBreatheChoice,vaultReadChoice];
class VaultChoice: DialogueChoice
    code = 1400
    selected(context) { return self.code == 1402 ? vaultFaceAction.perform(context.asker) : vaultDo(self.code,context.asker); }
;
vaultCallChoice: VaultChoice id = 'guide' labelId = 'vault.guide' code = 1401;
vaultFaceChoice: VaultChoice id = 'face' labelId = 'vault.face' code = 1402;
vaultBreatheChoice: VaultChoice id = 'breathe' labelId = 'vault.breathe' code = 1403;
vaultReadChoice: VaultChoice id = 'read' labelId = 'vault.read' code = 1404;
vaultCallLabel: Message id = 'vault.guide' text = 'Ask the guide to stand nearby';
vaultFaceLabel: Message id = 'vault.face' text = 'Face the impossible reflection';
vaultBreatheLabel: Message id = 'vault.breathe' text = 'Take a quiet breath';
vaultReadLabel: Message id = 'vault.read' text = 'Read the revealed inscription';
modify gameMain initialRoom = vault;
startup() { rpgRandom.seed(27); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args) { if (verb == 1400) return vaultStatus(); return vhylAct(verb,args); }
