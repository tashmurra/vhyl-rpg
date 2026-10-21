#include "expanded-nature-observation.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = bleedProfile;
natureObserveAction: RpgExpandedNatureObservationAction observation = natureObservation;
natureRollbackAction: RpgExpandedNatureObservationAction observation = natureObservation
    perform(actor) { inherited(actor); throw new RpgError(); }
;
natureObserveVerb: Verb code = 20510 action = natureObserveAction label = 'observe-nature';
natureRollbackVerb: Verb code = 20511 action = natureRollbackAction label = 'rollback-nature';
grammar command(natureObserveCmd): 'observe' 'nature' : Command action = natureObserveAction;
grammar command(natureRollbackCmd): 'rollback' 'nature' : Command action = natureRollbackAction;
natureGuide: Actor 'guide' location(bleedRoom) vocab = 'guide';
natureConversation: Conversation id = 'nature-plan' target = natureGuide choices = [natureObserveChoice,natureRollbackChoice];
class NatureRouteChoice: DialogueChoice
    natureAction = nil
    selected(context) { return self.natureAction.perform(context.asker); }
;
natureObserveChoice: NatureRouteChoice id = 'observe' labelId = 'nature.observe' natureAction = natureObserveAction;
natureRollbackChoice: NatureRouteChoice id = 'rollback' labelId = 'nature.rollback' natureAction = natureRollbackAction;
natureObserveLabel: Message id = 'nature.observe' text = 'Examine the plants';
natureRollbackLabel: Message id = 'nature.rollback' text = 'Exercise observation rollback';
modify BleedTestAction
    exec(context)
    {
        if (bleedInput.code == 20500) { player.rpgProfile = nil; return nil; }
        return inherited(context);
    }
;
