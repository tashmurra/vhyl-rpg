#include "expanded-chemical.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = crossPhysician;
sensePreviewAction: RpgExpandedSenseObservationAction observation = chemicalObservationFixture operation = 'preview';
senseResolveAction: RpgExpandedSenseObservationAction observation = chemicalObservationFixture;
senseRollbackAction: RpgExpandedSenseObservationAction observation = chemicalObservationFixture
    perform(actor) { inherited(actor); throw new RpgError(); }
;
sensePreviewVerb: Verb code = 27510 action = sensePreviewAction label = 'assess-sense';
senseResolveVerb: Verb code = 27511 action = senseResolveAction label = 'resolve-sense';
senseRollbackVerb: Verb code = 27512 action = senseRollbackAction label = 'rollback-sense';
grammar command(sensePreviewCmd): 'assess' 'sense' : Command action = sensePreviewAction;
grammar command(senseResolveCmd): 'resolve' 'sense' : Command action = senseResolveAction;
grammar command(senseRollbackCmd): 'rollback' 'sense' : Command action = senseRollbackAction;
senseGuide: Actor 'guide' location(healthRoom) vocab = 'guide';
senseConversation: Conversation id = 'sensory-observation' target = senseGuide choices = [sensePreviewChoice,senseResolveChoice,senseRollbackChoice];
class SenseRouteChoice: DialogueChoice
    senseAction = nil
    selected(context) { return self.senseAction.perform(context.asker); }
;
sensePreviewChoice: SenseRouteChoice id = 'preview' labelId = 'sense.preview' senseAction = sensePreviewAction;
senseResolveChoice: SenseRouteChoice id = 'resolve' labelId = 'sense.resolve' senseAction = senseResolveAction;
senseRollbackChoice: SenseRouteChoice id = 'rollback' labelId = 'sense.rollback' senseAction = senseRollbackAction;
sensePreviewLabel: Message id = 'sense.preview' text = 'Assess the observation';
senseResolveLabel: Message id = 'sense.resolve' text = 'Attempt the observation';
senseRollbackLabel: Message id = 'sense.rollback' text = 'Exercise observation rollback';
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 27500) { chemicalContextFixture.sense = 'taste'; return nil; }
        if (healthInput.code == 27501) { player.rpgProfile = nil; return nil; }
        if (healthInput.code == 27502) { player.rpgProfile = beggingObserver; return nil; }
        return inherited(context);
    }
;
