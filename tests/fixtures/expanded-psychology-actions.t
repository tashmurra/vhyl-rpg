#include "expanded-psychology-disclosure.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = crossPhysician;
psychologyAssessAction: RpgExpandedPsychologyAction assessment = psychologyAssessment;
psychologyReceiveAction: RpgExpandedPsychologyAction assessment = psychologyAssessment disclosure = psychologyDisclosure operation = 'receive';
psychologyRollbackAction: RpgExpandedPsychologyAction assessment = psychologyAssessment
    perform(actor) { inherited(actor); throw new RpgError(); }
;
psychologyAssessVerb: Verb code = 21310 action = psychologyAssessAction label = 'assess-behavior';
psychologyReceiveVerb: Verb code = 21311 action = psychologyReceiveAction label = 'receive-finding';
psychologyRollbackVerb: Verb code = 21312 action = psychologyRollbackAction label = 'rollback-assessment';
grammar command(psychologyAssessCmd): 'assess' 'behavior' : Command action = psychologyAssessAction;
grammar command(psychologyReceiveCmd): 'receive' 'finding' : Command action = psychologyReceiveAction;
grammar command(psychologyRollbackCmd): 'rollback' 'assessment' : Command action = psychologyRollbackAction;
psychologyGuide: Actor 'guide' location(healthRoom) vocab = 'guide';
psychologyConversation: Conversation id = 'psychology-plan' target = psychologyGuide choices = [psychologyAssessChoice,psychologyReceiveChoice,psychologyRollbackChoice];
class PsychologyRouteChoice: DialogueChoice
    psychologyAction = nil
    selected(context) { return self.psychologyAction.perform(context.asker); }
;
psychologyAssessChoice: PsychologyRouteChoice id = 'assess' labelId = 'psychology.assess' psychologyAction = psychologyAssessAction;
psychologyReceiveChoice: PsychologyRouteChoice id = 'receive' labelId = 'psychology.receive' psychologyAction = psychologyReceiveAction;
psychologyRollbackChoice: PsychologyRouteChoice id = 'rollback' labelId = 'psychology.rollback' psychologyAction = psychologyRollbackAction;
psychologyAssessLabel: Message id = 'psychology.assess' text = 'Assess the behavior';
psychologyReceiveLabel: Message id = 'psychology.receive' text = 'Receive the finding';
psychologyRollbackLabel: Message id = 'psychology.rollback' text = 'Exercise assessment rollback';
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 21300) { player.rpgProfile = nil; return nil; }
        return inherited(context);
    }
;
