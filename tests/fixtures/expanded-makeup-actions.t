#include "expanded-makeup.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = crossPhysician;
makeupPreviewAction: RpgExpandedMakeupAction application = makeupApplicationFixture operation = 'preview';
makeupApplyAction: RpgExpandedMakeupAction application = makeupApplicationFixture;
makeupEndAction: RpgExpandedMakeupAction application = makeupApplicationFixture operation = 'end' endEvidence = 'The wearer has removed the cosmetics';
makeupRollbackAction: RpgExpandedMakeupAction application = makeupApplicationFixture
    perform(actor) { inherited(actor); throw new RpgError(); }
;
makeupPreviewVerb: Verb code = 25910 action = makeupPreviewAction label = 'assess-makeup';
makeupApplyVerb: Verb code = 25911 action = makeupApplyAction label = 'apply-makeup';
makeupEndVerb: Verb code = 25912 action = makeupEndAction label = 'end-makeup';
makeupRollbackVerb: Verb code = 25913 action = makeupRollbackAction label = 'rollback-makeup';
grammar command(makeupPreviewCmd): 'assess' 'makeup' : Command action = makeupPreviewAction;
grammar command(makeupApplyCmd): 'apply' 'makeup' : Command action = makeupApplyAction;
grammar command(makeupEndCmd): 'end' 'makeup' : Command action = makeupEndAction;
grammar command(makeupRollbackCmd): 'rollback' 'makeup' : Command action = makeupRollbackAction;
makeupGuide: Actor 'guide' location(healthRoom) vocab = 'guide';
makeupConversation: Conversation id = 'makeup-plan' target = makeupGuide choices = [makeupPreviewChoice,makeupApplyChoice,makeupEndChoice,makeupRollbackChoice];
class MakeupRouteChoice: DialogueChoice
    makeupAction = nil
    selected(context) { return self.makeupAction.perform(context.asker); }
;
makeupPreviewChoice: MakeupRouteChoice id = 'preview' labelId = 'makeup.preview' makeupAction = makeupPreviewAction;
makeupApplyChoice: MakeupRouteChoice id = 'apply' labelId = 'makeup.apply' makeupAction = makeupApplyAction;
makeupEndChoice: MakeupRouteChoice id = 'end' labelId = 'makeup.end' makeupAction = makeupEndAction;
makeupRollbackChoice: MakeupRouteChoice id = 'rollback' labelId = 'makeup.rollback' makeupAction = makeupRollbackAction;
makeupPreviewLabel: Message id = 'makeup.preview' text = 'Assess the cosmetic work';
makeupApplyLabel: Message id = 'makeup.apply' text = 'Apply theatrical makeup';
makeupEndLabel: Message id = 'makeup.end' text = 'Record the removed presentation';
makeupRollbackLabel: Message id = 'makeup.rollback' text = 'Exercise application rollback';
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 25900) { player.rpgProfile = nil; return nil; }
        if (healthInput.code == 25901) { player.rpgProfile = beggingObserver; return nil; }
        if (healthInput.code == 25902) { player.rpgProfile = crossPhysician; return nil; }
        return inherited(context);
    }
;
