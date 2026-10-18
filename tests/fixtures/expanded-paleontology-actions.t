#include "expanded-paleontology-disclosure.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = crossPhysician;
paleontologyAssessAction: RpgExpandedPaleontologyAction assessment = paleontologyAssessment;
paleontologyReceiveAction: RpgExpandedPaleontologyAction assessment = paleontologyAssessment disclosure = paleontologyDisclosure operation = 'receive';
paleontologyRollbackAction: RpgExpandedPaleontologyAction assessment = paleontologyAssessment
    perform(actor) { inherited(actor); throw new RpgError(); }
;
paleontologyAssessVerb: Verb code = 22110 action = paleontologyAssessAction label = 'study-fossil';
paleontologyReceiveVerb: Verb code = 22111 action = paleontologyReceiveAction label = 'receive-finding';
paleontologyRollbackVerb: Verb code = 22112 action = paleontologyRollbackAction label = 'rollback-assessment';
grammar command(paleontologyAssessCmd): 'study' 'fossil' : Command action = paleontologyAssessAction;
grammar command(paleontologyReceiveCmd): 'receive' 'finding' : Command action = paleontologyReceiveAction;
grammar command(paleontologyRollbackCmd): 'rollback' 'assessment' : Command action = paleontologyRollbackAction;
paleontologyGuide: Actor 'guide' location(healthRoom) vocab = 'guide';
paleontologyConversation: Conversation id = 'paleontology-plan' target = paleontologyGuide choices = [paleontologyAssessChoice,paleontologyReceiveChoice,paleontologyRollbackChoice];
class PaleontologyRouteChoice: DialogueChoice
    paleontologyAction = nil
    selected(context) { return self.paleontologyAction.perform(context.asker); }
;
paleontologyAssessChoice: PaleontologyRouteChoice id = 'assess' labelId = 'paleontology.assess' paleontologyAction = paleontologyAssessAction;
paleontologyReceiveChoice: PaleontologyRouteChoice id = 'receive' labelId = 'paleontology.receive' paleontologyAction = paleontologyReceiveAction;
paleontologyRollbackChoice: PaleontologyRouteChoice id = 'rollback' labelId = 'paleontology.rollback' paleontologyAction = paleontologyRollbackAction;
paleontologyAssessLabel: Message id = 'paleontology.assess' text = 'Study the fossil';
paleontologyReceiveLabel: Message id = 'paleontology.receive' text = 'Receive the finding';
paleontologyRollbackLabel: Message id = 'paleontology.rollback' text = 'Exercise assessment rollback';
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 22100) { player.rpgProfile = nil; return nil; }
        return inherited(context);
    }
;
