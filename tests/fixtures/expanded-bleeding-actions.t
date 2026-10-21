#include "expanded-bleeding.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = bleedHealer;
aidPreviewAction: RpgExpandedBleedingAidAction care = bleedAid;
aidStartAction: RpgExpandedBleedingAidAction care = bleedAid operation = 'start';
aidDueAction: RpgExpandedBleedingAidAction care = bleedAid operation = 'completion-preview';
aidCompleteAction: RpgExpandedBleedingAidAction care = bleedAid operation = 'complete';
aidCancelAction: RpgExpandedBleedingAidAction care = bleedAid operation = 'cancel';
aidRollbackAction: RpgExpandedBleedingAidAction care = bleedAid operation = 'complete'
    perform(actor) { inherited(actor); throw new RpgError(); }
;
aidPreviewVerb: Verb code = 26110 action = aidPreviewAction label = 'assess-care';
aidStartVerb: Verb code = 26111 action = aidStartAction label = 'start-care';
aidDueVerb: Verb code = 26112 action = aidDueAction label = 'assess-completion';
aidCompleteVerb: Verb code = 26113 action = aidCompleteAction label = 'complete-care';
aidCancelVerb: Verb code = 26114 action = aidCancelAction label = 'cancel-care';
aidRollbackVerb: Verb code = 26115 action = aidRollbackAction label = 'rollback-care';
grammar command(aidPreviewCmd): 'assess' 'care' : Command action = aidPreviewAction;
grammar command(aidStartCmd): 'start' 'care' : Command action = aidStartAction;
grammar command(aidDueCmd): 'assess' 'completion' : Command action = aidDueAction;
grammar command(aidCompleteCmd): 'complete' 'care' : Command action = aidCompleteAction;
grammar command(aidCancelCmd): 'cancel' 'care' : Command action = aidCancelAction;
grammar command(aidRollbackCmd): 'rollback' 'care' : Command action = aidRollbackAction;
aidGuide: Actor 'guide' location(bleedRoom) vocab = 'guide';
aidConversation: Conversation id = 'bleeding-care' target = aidGuide
    choices = [aidPreviewChoice,aidStartChoice,aidDueChoice,aidCompleteChoice,aidCancelChoice,aidRollbackChoice];
class AidRouteChoice: DialogueChoice
    careAction = nil
    selected(context) { return self.careAction.perform(context.asker); }
;
aidPreviewChoice: AidRouteChoice id = 'preview' labelId = 'aid.preview' careAction = aidPreviewAction;
aidStartChoice: AidRouteChoice id = 'start' labelId = 'aid.start' careAction = aidStartAction;
aidDueChoice: AidRouteChoice id = 'completion-preview' labelId = 'aid.due' careAction = aidDueAction;
aidCompleteChoice: AidRouteChoice id = 'complete' labelId = 'aid.complete' careAction = aidCompleteAction;
aidCancelChoice: AidRouteChoice id = 'cancel' labelId = 'aid.cancel' careAction = aidCancelAction;
aidRollbackChoice: AidRouteChoice id = 'rollback' labelId = 'aid.rollback' careAction = aidRollbackAction;
aidPreviewLabel: Message id = 'aid.preview' text = 'Assess bleeding care';
aidStartLabel: Message id = 'aid.start' text = 'Begin pressure treatment';
aidDueLabel: Message id = 'aid.due' text = 'Assess completion of care';
aidCompleteLabel: Message id = 'aid.complete' text = 'Complete pressure treatment';
aidCancelLabel: Message id = 'aid.cancel' text = 'Interrupt this treatment';
aidRollbackLabel: Message id = 'aid.rollback' text = 'Exercise treatment rollback';
modify BleedTestAction
    exec(context)
    {
        if (bleedInput.code == 80) { player.rpgProfile = nil; return nil; }
        if (bleedInput.code == 81) { player.rpgProfile = bleedProfile; return nil; }
        if (bleedInput.code == 82) { player.rpgProfile = bleedHealer; return nil; }
        return inherited(context);
    }
;
