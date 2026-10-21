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
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-traits.t>
#include <vhyl-rpg-expanded-stress.t>

vault: Room 'Echo Vault'
    desc { return vaultSay('The archive clock has stopped, but its reflection still ticks. Your guide waits by the stairs. Try call guide, face reflection, breathe, read inscription, or status.'); }
;
vaultGuide: Actor 'guide' location(vault) vocab = 'guide';
vaultRules: RpgExpandedRules scaledInjuryShock = true;
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
    if (code >= 1420) return vaultAftermath(code,actor);
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
    rpgExpandedReject('vault-action'); return nil;
}
class VaultAction: Action code = 1400 exec(context) { return vaultDo(self.code,player); };
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
turn(tokens) { return rpgDispatchTurn(tokens); }
act(verb,args) { if (verb == 1429) return vaultAftermathStatus(); if (verb == 1400) return vaultStatus(); return rpgDispatchAction(verb,args); }


/* A second connected scene keeps the original reflection vignette intact. */
vaultCabinetOccurrence: object;
vaultCabinetContext: RpgExpandedFearContext profile = vaultProfile approved = true monsters = true monsterPenalty = 10
    evidence = 'Opening the cabinet reveals an impossible archive of the visitor own future';
vaultCabinetRuling: RpgExpandedLowScoreFearDecision entry = vaultCabinetEvent row = 27 approved = true
    evidence = 'The unrollable initial fear is assigned a faint and lasting curiosity, with no invented roll';
vaultCabinetEvent: RpgExpandedFearEvent id = 'future-cabinet' occurrence = vaultCabinetOccurrence
    context = vaultCabinetContext lowScoreDecision = vaultCabinetRuling;
vaultCuriosity: RpgExpandedCuriosity approved = true selfControlRating = 6;
vaultAcquisition: RpgExpandedFearMentalAcquisition id = 'future-curiosity' eventId = 'future-cabinet'
    profile = vaultProfile trait = vaultCuriosity tableTotal = 23 approved = true
    evidence = 'The visitor develops a lasting need to investigate impossible records';
vaultFaint: RpgExpandedFearFaint id = 'future-cabinet' context = vaultCabinetContext tableTotal = 18 approved = true
    evidence = 'The recorded compound response includes a faint and possible collapse injury';
vaultCompound: RpgExpandedFearTraitCompound id = 'future-cabinet' context = vaultCabinetContext
    tableTotal = 27 acquisition = vaultAcquisition episode = vaultFaint;
vaultFootstepOccurrence: object;
vaultFootstepContext: RpgExpandedFearContext profile = vaultProfile approved = true monsters = true monsterPenalty = 10
    evidence = 'Footsteps repeat from a sealed passage while the cabinet closes itself';
vaultFootstepRuling: RpgExpandedLowScoreFearDecision entry = vaultFootstepEvent row = 21 approved = true
    evidence = 'The author records timed panic at the prohibited-roll boundary';
vaultFootstepEvent: RpgExpandedFearEvent id = 'sealed-footsteps' occurrence = vaultFootstepOccurrence
    context = vaultFootstepContext lowScoreDecision = vaultFootstepRuling;
vaultPanic: RpgExpandedFearPanic id = 'sealed-footsteps' context = vaultFootstepContext approved = true
    behaviorKind = 'cry' behavior = 'Sit on the stair and cry until composure returns' evidence = 'Recorded panic response';
vaultStressPolicy: RpgExpandedStressPolicy;
vaultStress: RpgExpandedStressState profile = vaultProfile policy = vaultStressPolicy;
vaultRest: RpgExpandedStressRecovery id = 'safe-hour-0' state = vaultStress safe = true evidence = 'The guide guards the quiet landing';
modify vaultState memories = 0 response = nil rest = vaultRest;
modify dialogueTurn stressResolution = (vaultState.response) stressRecovery = (vaultState.rest);
vaultAftermathStatus()
{
    event('vault.aftermath'); eventValue(vaultCompound.result == nil ? 0 : 1);
    eventValue(vaultProfile.unconscious ? 1 : 0); eventValue(vaultProfile.traits.length());
    eventValue(vaultPanic.startedAt == nil ? 'new' : vaultPanic.completedAt == nil ? 'active' : 'finished');
    eventValue(vaultStress.balance); eventValue(vaultStress.pending() == nil ? 0 : vaultStress.pending().threshold);
    eventValue(vaultStress.boundPolicy == nil ? 0 : vaultStress.strainPenalty()); eventValue(rpgLedger.seconds); return nil;
}
vaultAftermath(code,actor)
{
    if (actor != player) rpgExpandedReject('vault-aftermath-owner');
    if (vaultProfile.stressPendingReason() != nil && !holds([1425,1426,1427,1428,1429],code))
        return vaultSay('Choose coping, strain or fear for the pending stress decision first.');
    if (code == 1429) return vaultAftermathStatus();
    if (code == 1420)
    {
        if (!vaultState.inscriptionRead) return vaultSay('Find the key beneath the stair first.');
        vaultProfile.creationComplete = true; vaultCabinetEvent.resolve(); vaultCabinetEvent.applyConsequence(vaultCompound);
        return vaultSay('The cabinet contains tomorrow in your handwriting. You faint; the need to understand it will remain. Try recover.');
    }
    if (code == 1421)
    {
        if (vaultFaint.startedAt == nil || vaultFaint.completedAt != nil) return vaultSay('You are not in the cabinet faint.');
        if (rpgLedger.seconds < vaultFaint.nextCheckAt) rpgSpendTime(vaultFaint.nextCheckAt-rpgLedger.seconds);
        local recovery = new RpgExpandedFearFaintRecovery(); recovery.id = 'vault-faint-' + toString(rpgLedger.seconds); recovery.episode = vaultFaint;
        recovery.apply(); return vaultSay(vaultProfile.unconscious ? 'The guide keeps watch. Try recover again.' : 'You wake, still determined to investigate. Try hear footsteps.');
    }
    if (code == 1422)
    {
        if (vaultFaint.completedAt == nil) return vaultSay('Recover from the cabinet first.');
        vaultFootstepEvent.resolve(); vaultFootstepEvent.applyConsequence(vaultPanic);
        return vaultSay('The footsteps approach through solid stone. You sit down and cry. Try wait panic.');
    }
    if (code == 1423)
    {
        if (vaultPanic.startedAt == nil || vaultPanic.completedAt != nil) return vaultSay('There is no active panic interval.');
        if (rpgLedger.seconds < vaultPanic.nextCheckAt)
        {
            local gate = new RpgExpandedActionGate(); gate.id = 'vault-cry-gate-' + toString(rpgLedger.seconds);
            gate.profile = vaultProfile; gate.purpose = 'do-nothing'; gate.evidence = 'Quiet stationary crying';
            local cry = new RpgExpandedFearPanicCrying(); cry.id = 'vault-cry-' + toString(rpgLedger.seconds);
            cry.episode = vaultPanic; cry.seconds = vaultPanic.nextCheckAt-rpgLedger.seconds; cry.healthGate = gate; cry.apply();
        }
        local recovery = new RpgExpandedFearPanicRecovery(); recovery.id = 'vault-panic-' + toString(rpgLedger.seconds);
        recovery.episode = vaultPanic; recovery.apply();
        return vaultSay(vaultPanic.completedAt == nil ? 'The fear persists. Try wait panic again.' : 'Composure returns. Later you may remember an incident, then rest hour.');
    }
    if (code == 1424)
    {
        if (vaultPanic.completedAt == nil) return vaultSay('Finish the panic scene first.');
        if (vaultState.memories >= 4) return vaultSay('All four authored reminders have been recorded.');
        vaultStress.configure(); vaultState.memories += 1;
        local gain = new RpgExpandedStressGain(); gain.state = vaultStress; gain.id = 'reminder-' + toString(vaultState.memories);
        gain.cause = gain.id; gain.severity = 'severe';
        gain.evidence = ['The cabinet handwriting recurs on a safe letter','The sealed corridor echoes again',
            'The guide finds another impossible date','The archive bell rings without a mechanism'][vaultState.memories];
        gain.apply();
        if (vaultStress.pending() != nil)
        {
            vaultState.response = new RpgExpandedStressResolution(); vaultState.response.decision = vaultStress.pending();
            vaultState.response.evidence = 'The player and author select the response to this threshold';
        }
        return vaultSay('The distinct reminder adds three stress. At a threshold choose cope, accept strain, or face memory.');
    }
    if (holds([1425,1426,1427],code))
    {
        if (vaultStress.pending() == nil) return vaultSay('No stress decision is pending.');
        local response = vaultState.response; response.choice = code == 1425 ? 'coping' : code == 1426 ? 'strain' : 'fear';
        if (code == 1427)
        {
            local context = new RpgExpandedFearContext(); context.profile = vaultProfile; context.approved = true;
            context.stimulusInput = 'internal'; context.evidence = 'An unsettling remembered pattern';
            local fear = new RpgExpandedFearEvent(); fear.id = 'memory-' + toString(vaultState.memories); fear.occurrence = response; fear.context = context;
            response.fearEvent = fear; response.apply();
            if (fear.result.row != nil)
            {
                local ruling = new RpgExpandedFearAdjudication(); ruling.id = 'memory-confusion-' + toString(vaultState.memories);
                ruling.entry = fear; ruling.mode = 'replace'; ruling.row = 4; ruling.reason = 'confusion'; ruling.approved = true;
                ruling.evidence = 'This authored recollection produces brief confusion rather than fresh physical harm'; ruling.apply();
                local stun = new RpgExpandedFearStun(); stun.id = fear.id; stun.context = context; stun.tableTotal = 4;
                stun.approved = true; stun.evidence = 'Brief confusion following the owned memory check'; response.completeFear(stun);
            }
        }
        else response.apply();
        return vaultSay('The threshold decision is recorded. Stress remains until safe rest reduces it.');
    }
    if (code == 1428)
    {
        if (vaultStress.boundPolicy == nil) return vaultSay('The optional stress track has not been configured.');
        vaultState.rest.begin(); rpgSpendTime(vaultStressPolicy.recoverySeconds); vaultState.rest.complete();
        local rest = new RpgExpandedStressRecovery(); rest.id = 'safe-hour-' + toString(rpgLedger.seconds);
        rest.state = vaultStress; rest.safe = true; rest.evidence = 'Another guarded uninterrupted safe hour'; vaultState.rest = rest;
        return vaultSay('An uninterrupted safe hour passes. Recovery observes the daily limit and preserves independent aftermath.');
    }
    rpgExpandedReject('vault-aftermath-code'); return nil;
}
class VaultAftermathAction: VaultAction
    stressResolution = (holds([1425,1426,1427],self.code) ? vaultState.response : nil)
    stressRecovery = (self.code == 1428 ? vaultState.rest : nil)
;
vaultcabinetAction: VaultAftermathAction code = 1420;
vaultcabinetVerb: Verb code = 1420 action = vaultcabinetAction label = 'open cabinet';
grammar command(vaultcabinetCmd): 'open' 'cabinet' : Command action = vaultcabinetAction;
vaultcabinetChoice: VaultChoice id = 'cabinet' code = 1420 labelId = 'vault.cabinet';
vaultcabinetLabel: Message id = 'vault.cabinet' text = 'open cabinet';
vaultrecoverAction: VaultAftermathAction code = 1421;
vaultrecoverVerb: Verb code = 1421 action = vaultrecoverAction label = 'recover';
grammar command(vaultrecoverCmd): 'recover' : Command action = vaultrecoverAction;
vaultrecoverChoice: VaultChoice id = 'recover' code = 1421 labelId = 'vault.recover';
vaultrecoverLabel: Message id = 'vault.recover' text = 'recover';
vaultfootstepsAction: VaultAftermathAction code = 1422;
vaultfootstepsVerb: Verb code = 1422 action = vaultfootstepsAction label = 'hear footsteps';
grammar command(vaultfootstepsCmd): 'hear' 'footsteps' : Command action = vaultfootstepsAction;
vaultfootstepsChoice: VaultChoice id = 'footsteps' code = 1422 labelId = 'vault.footsteps';
vaultfootstepsLabel: Message id = 'vault.footsteps' text = 'hear footsteps';
vaultpanicAction: VaultAftermathAction code = 1423;
vaultpanicVerb: Verb code = 1423 action = vaultpanicAction label = 'wait panic';
grammar command(vaultpanicCmd): 'wait' 'panic' : Command action = vaultpanicAction;
vaultpanicChoice: VaultChoice id = 'panic' code = 1423 labelId = 'vault.panic';
vaultpanicLabel: Message id = 'vault.panic' text = 'wait panic';
vaultrememberAction: VaultAftermathAction code = 1424;
vaultrememberVerb: Verb code = 1424 action = vaultrememberAction label = 'remember';
grammar command(vaultrememberCmd): 'remember' : Command action = vaultrememberAction;
vaultrememberChoice: VaultChoice id = 'remember' code = 1424 labelId = 'vault.remember';
vaultrememberLabel: Message id = 'vault.remember' text = 'remember';
vaultcopeAction: VaultAftermathAction code = 1425;
vaultcopeVerb: Verb code = 1425 action = vaultcopeAction label = 'cope';
grammar command(vaultcopeCmd): 'cope' : Command action = vaultcopeAction;
vaultcopeChoice: VaultChoice id = 'cope' code = 1425 labelId = 'vault.cope';
vaultcopeLabel: Message id = 'vault.cope' text = 'cope';
vaultstrainAction: VaultAftermathAction code = 1426;
vaultstrainVerb: Verb code = 1426 action = vaultstrainAction label = 'accept strain';
grammar command(vaultstrainCmd): 'accept' 'strain' : Command action = vaultstrainAction;
vaultstrainChoice: VaultChoice id = 'strain' code = 1426 labelId = 'vault.strain';
vaultstrainLabel: Message id = 'vault.strain' text = 'accept strain';
vaultmemoryAction: VaultAftermathAction code = 1427;
vaultmemoryVerb: Verb code = 1427 action = vaultmemoryAction label = 'face memory';
grammar command(vaultmemoryCmd): 'face' 'memory' : Command action = vaultmemoryAction;
vaultmemoryChoice: VaultChoice id = 'memory' code = 1427 labelId = 'vault.memory';
vaultmemoryLabel: Message id = 'vault.memory' text = 'face memory';
vaultrestAction: VaultAftermathAction code = 1428;
vaultrestVerb: Verb code = 1428 action = vaultrestAction label = 'rest hour';
grammar command(vaultrestCmd): 'rest' 'hour' : Command action = vaultrestAction;
vaultrestChoice: VaultChoice id = 'rest' code = 1428 labelId = 'vault.rest';
vaultrestLabel: Message id = 'vault.rest' text = 'rest hour';
modify vaultPlan choices = [vaultCallChoice,vaultFaceChoice,vaultBreatheChoice,vaultReadChoice,vaultcabinetChoice,vaultrecoverChoice,vaultfootstepsChoice,vaultpanicChoice,vaultrememberChoice,vaultcopeChoice,vaultstrainChoice,vaultmemoryChoice,vaultrestChoice];
