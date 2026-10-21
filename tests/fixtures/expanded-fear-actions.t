#include "expanded-fear-event.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = fearProfile;
fearPreviewAction: RpgExpandedFearAction entry = ownedFearEvent operation = 'preview';
fearResolveAction: RpgExpandedFearAction entry = ownedFearEvent;
fearConsequenceAction: RpgExpandedFearAction entry = ownedFearEvent consequence = fearEpisode operation = 'consequence';
fearRollbackAction: RpgExpandedFearAction entry = ownedFearEvent
    perform(actor) { inherited(actor); throw new RpgError(); }
;
fearPreviewVerb: Verb code = 28710 action = fearPreviewAction label = 'assess-fear';
fearResolveVerb: Verb code = 28711 action = fearResolveAction label = 'face-fear';
fearConsequenceVerb: Verb code = 28712 action = fearConsequenceAction label = 'resolve-reaction';
fearRollbackVerb: Verb code = 28713 action = fearRollbackAction label = 'rollback-fear';
grammar command(fearPreviewCmd): 'assess' 'fear' : Command action = fearPreviewAction;
grammar command(fearResolveCmd): 'face' 'fear' : Command action = fearResolveAction;
grammar command(fearConsequenceCmd): 'resolve' 'reaction' : Command action = fearConsequenceAction;
grammar command(fearRollbackCmd): 'rollback' 'fear' : Command action = fearRollbackAction;
fearGuide: Actor 'guide' location(fearRoom) vocab = 'guide';
fearConversation: Conversation id = 'fear-actions' target = fearGuide choices = [fearPreviewChoice,fearResolveChoice,fearConsequenceChoice];
class FearRouteChoice: DialogueChoice
    fearAction = nil
    selected(context) { return self.fearAction.perform(context.asker); }
;
fearPreviewChoice: FearRouteChoice id = 'preview' labelId = 'fear.preview' fearAction = fearPreviewAction;
fearResolveChoice: FearRouteChoice id = 'resolve' labelId = 'fear.resolve' fearAction = fearResolveAction;
fearConsequenceChoice: FearRouteChoice id = 'consequence' labelId = 'fear.consequence' fearAction = fearConsequenceAction;
fearPreviewLabel: Message id = 'fear.preview' text = 'Assess this unsettling event';
fearResolveLabel: Message id = 'fear.resolve' text = 'Face the unsettling event';
fearConsequenceLabel: Message id = 'fear.consequence' text = 'Resolve the authored reaction';
modify FearTestAction
    exec(context)
    {
        if (fearInput.code == 510) { player.rpgProfile = nil; return nil; }
        return inherited(context);
    }
;
