#include "expanded-tracking-encounter.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = crossPhysician;
trackingPreviewAction: RpgExpandedTrackingAction request = trackingAcquisitionFixture operation = 'preview';
trackingResolveAction: RpgExpandedTrackingAction request = trackingAcquisitionFixture;
trackingRollbackAction: RpgExpandedTrackingAction request = trackingAcquisitionFixture
    perform(actor) { inherited(actor); throw new RpgError(); }
;
trackingPreviewVerb: Verb code = 29010 action = trackingPreviewAction label = 'assess-tracking';
trackingResolveVerb: Verb code = 29011 action = trackingResolveAction label = 'resolve-tracking';
trackingRollbackVerb: Verb code = 29012 action = trackingRollbackAction label = 'rollback-tracking';
grammar command(trackingPreviewCmd): 'assess' 'tracking' : Command action = trackingPreviewAction;
grammar command(trackingResolveCmd): 'resolve' 'tracking' : Command action = trackingResolveAction;
grammar command(trackingRollbackCmd): 'rollback' 'tracking' : Command action = trackingRollbackAction;
trackingGuide: Actor 'guide' location(healthRoom) vocab = 'guide';
trackingConversation: Conversation id = 'trail-tracking' target = trackingGuide choices = [trackingPreviewChoice,trackingResolveChoice,trackingRollbackChoice];
class TrackingRouteChoice: DialogueChoice
    trackingAction = nil
    selected(context) { return self.trackingAction.perform(context.asker); }
;
trackingPreviewChoice: TrackingRouteChoice id = 'preview' labelId = 'tracking.preview' trackingAction = trackingPreviewAction;
trackingResolveChoice: TrackingRouteChoice id = 'resolve' labelId = 'tracking.resolve' trackingAction = trackingResolveAction;
trackingRollbackChoice: TrackingRouteChoice id = 'rollback' labelId = 'tracking.rollback' trackingAction = trackingRollbackAction;
trackingPreviewLabel: Message id = 'tracking.preview' text = 'Assess the tracking';
trackingResolveLabel: Message id = 'tracking.resolve' text = 'Attempt the tracking';
trackingRollbackLabel: Message id = 'tracking.rollback' text = 'Exercise tracking rollback';
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 29001) { player.rpgProfile = nil; return nil; }
        if (healthInput.code == 29002) { player.rpgProfile = beggingObserver; return nil; }
        if (healthInput.code == 29003)
        { trackingPreviewAction.request = secondFollowStep; trackingResolveAction.request = secondFollowStep; trackingRollbackAction.request = secondFollowStep; return nil; }
        return inherited(context);
    }
;
