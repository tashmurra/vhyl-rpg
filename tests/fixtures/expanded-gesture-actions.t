#include "expanded-gesture-attempt.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = crossPhysician;
gesturePreviewAction: RpgExpandedGestureAction attempt = gestureAttemptFixture operation = 'preview';
gestureResolveAction: RpgExpandedGestureAction attempt = gestureAttemptFixture;
gestureRollbackAction: RpgExpandedGestureAction attempt = gestureAttemptFixture
    perform(actor) { inherited(actor); throw new RpgError(); }
;
gesturePreviewVerb: Verb code = 26710 action = gesturePreviewAction label = 'assess-signal';
gestureResolveVerb: Verb code = 26711 action = gestureResolveAction label = 'resolve-signal';
gestureRollbackVerb: Verb code = 26712 action = gestureRollbackAction label = 'rollback-signal';
grammar command(gesturePreviewCmd): 'assess' 'signal' : Command action = gesturePreviewAction;
grammar command(gestureResolveCmd): 'resolve' 'signal' : Command action = gestureResolveAction;
grammar command(gestureRollbackCmd): 'rollback' 'signal' : Command action = gestureRollbackAction;
gestureGuide: Actor 'guide' location(healthRoom) vocab = 'guide';
gestureConversation: Conversation id = 'doorway-signal' target = gestureGuide
    choices = [gesturePreviewChoice,gestureResolveChoice,gestureRollbackChoice];
class GestureRouteChoice: DialogueChoice
    gestureAction = nil
    selected(context) { return self.gestureAction.perform(context.asker); }
;
gesturePreviewChoice: GestureRouteChoice id = 'preview' labelId = 'gesture.preview' gestureAction = gesturePreviewAction;
gestureResolveChoice: GestureRouteChoice id = 'resolve' labelId = 'gesture.resolve' gestureAction = gestureResolveAction;
gestureRollbackChoice: GestureRouteChoice id = 'rollback' labelId = 'gesture.rollback' gestureAction = gestureRollbackAction;
gesturePreviewLabel: Message id = 'gesture.preview' text = 'Assess this simple signal';
gestureResolveLabel: Message id = 'gesture.resolve' text = 'Attempt this simple signal';
gestureRollbackLabel: Message id = 'gesture.rollback' text = 'Exercise signal rollback';
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 26700) { player.rpgProfile = nil; return nil; }
        if (healthInput.code == 26701) { player.rpgProfile = beggingObserver; return nil; }
        return inherited(context);
    }
;
