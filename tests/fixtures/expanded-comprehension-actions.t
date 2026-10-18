#include "expanded-sense-comprehension.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = crossPhysician;
comprehensionPreviewAction: RpgExpandedSenseComprehensionAction comprehension = comprehensionFixture operation = 'preview';
comprehensionResolveAction: RpgExpandedSenseComprehensionAction comprehension = comprehensionFixture;
comprehensionRollbackAction: RpgExpandedSenseComprehensionAction comprehension = comprehensionFixture
    perform(actor) { inherited(actor); throw new RpgError(); }
;
comprehensionPreviewVerb: Verb code = 27810 action = comprehensionPreviewAction label = 'assess-comprehension';
comprehensionResolveVerb: Verb code = 27811 action = comprehensionResolveAction label = 'resolve-comprehension';
comprehensionRollbackVerb: Verb code = 27812 action = comprehensionRollbackAction label = 'rollback-comprehension';
grammar command(comprehensionPreviewCmd): 'assess' 'comprehension' : Command action = comprehensionPreviewAction;
grammar command(comprehensionResolveCmd): 'resolve' 'comprehension' : Command action = comprehensionResolveAction;
grammar command(comprehensionRollbackCmd): 'rollback' 'comprehension' : Command action = comprehensionRollbackAction;
comprehensionGuide: Actor 'guide' location(healthRoom) vocab = 'guide';
comprehensionConversation: Conversation id = 'sensory-observation' target = comprehensionGuide choices = [comprehensionPreviewChoice,comprehensionResolveChoice,comprehensionRollbackChoice];
class ComprehensionRouteChoice: DialogueChoice
    comprehensionAction = nil
    selected(context) { return self.comprehensionAction.perform(context.asker); }
;
comprehensionPreviewChoice: ComprehensionRouteChoice id = 'preview' labelId = 'comprehension.preview' comprehensionAction = comprehensionPreviewAction;
comprehensionResolveChoice: ComprehensionRouteChoice id = 'resolve' labelId = 'comprehension.resolve' comprehensionAction = comprehensionResolveAction;
comprehensionRollbackChoice: ComprehensionRouteChoice id = 'rollback' labelId = 'comprehension.rollback' comprehensionAction = comprehensionRollbackAction;
comprehensionPreviewLabel: Message id = 'comprehension.preview' text = 'Assess the interpretation';
comprehensionResolveLabel: Message id = 'comprehension.resolve' text = 'Attempt the interpretation';
comprehensionRollbackLabel: Message id = 'comprehension.rollback' text = 'Exercise interpretation rollback';
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 27801) { player.rpgProfile = nil; return nil; }
        if (healthInput.code == 27802) { player.rpgProfile = beggingObserver; return nil; }
        return inherited(context);
    }
;
