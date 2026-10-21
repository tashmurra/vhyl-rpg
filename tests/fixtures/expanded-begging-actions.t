#include "expanded-begging-hour.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = crossPhysician;
beggingPreviewAction: RpgExpandedBeggingAction hour = beggingHour operation = 'preview';
beggingResolveAction: RpgExpandedBeggingAction hour = beggingHour;
beggingRollbackAction: RpgExpandedBeggingAction hour = beggingHour
    perform(actor) { inherited(actor); throw new RpgError(); }
;
beggingPreviewVerb: Verb code = 24410 action = beggingPreviewAction label = 'assess-begging';
beggingResolveVerb: Verb code = 24411 action = beggingResolveAction label = 'beg-hour';
beggingRollbackVerb: Verb code = 24412 action = beggingRollbackAction label = 'rollback-begging';
grammar command(beggingPreviewCmd): 'assess' 'begging' : Command action = beggingPreviewAction;
grammar command(beggingResolveCmd): 'beg' 'hour' : Command action = beggingResolveAction;
grammar command(beggingRollbackCmd): 'rollback' 'begging' : Command action = beggingRollbackAction;
beggingGuide: Actor 'guide' location(healthRoom) vocab = 'guide';
beggingConversation: Conversation id = 'begging-plan' target = beggingGuide choices = [beggingPreviewChoice,beggingResolveChoice,beggingRollbackChoice];
class BeggingRouteChoice: DialogueChoice
    beggingAction = nil
    selected(context) { return self.beggingAction.perform(context.asker); }
;
beggingPreviewChoice: BeggingRouteChoice id = 'preview' labelId = 'begging.preview' beggingAction = beggingPreviewAction;
beggingResolveChoice: BeggingRouteChoice id = 'resolve' labelId = 'begging.resolve' beggingAction = beggingResolveAction;
beggingRollbackChoice: BeggingRouteChoice id = 'rollback' labelId = 'begging.rollback' beggingAction = beggingRollbackAction;
beggingPreviewLabel: Message id = 'begging.preview' text = 'Assess the opportunity';
beggingResolveLabel: Message id = 'begging.resolve' text = 'Spend an hour begging';
beggingRollbackLabel: Message id = 'begging.rollback' text = 'Exercise hourly rollback';
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 24400) { player.rpgProfile = nil; return nil; }
        return inherited(context);
    }
;
