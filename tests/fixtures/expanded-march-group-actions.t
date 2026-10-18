#include "expanded-march-group.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = bleedProfile;
marchGroupAction: RpgExpandedMarchGroupAction group = marchGroup;
marchGroupRollback: RpgExpandedMarchGroupAction group = marchGroup
    perform(actor) { inherited(actor); throw new RpgError(); }
;
marchGroupVerb: Verb code = 23710 action = marchGroupAction label = 'march-together';
marchRollbackVerb: Verb code = 23711 action = marchGroupRollback label = 'rollback-march';
grammar command(marchTogetherCmd): 'march' 'together' : Command action = marchGroupAction;
grammar command(marchRollbackCmd): 'rollback' 'march' : Command action = marchGroupRollback;
marchGuide: Actor 'guide' location(bleedRoom) vocab = 'guide';
marchConversation: Conversation id = 'march-plan' target = marchGuide choices = [marchChoice,marchRollbackChoice];
class MarchRouteChoice: DialogueChoice
    marchAction = nil
    selected(context) { return self.marchAction.perform(context.asker); }
;
marchChoice: MarchRouteChoice id = 'march' labelId = 'march.go' marchAction = marchGroupAction;
marchRollbackChoice: MarchRouteChoice id = 'rollback' labelId = 'march.rollback' marchAction = marchGroupRollback;
marchLabel: Message id = 'march.go' text = 'March together for one hour';
marchRollbackLabel: Message id = 'march.rollback' text = 'Exercise march rollback';
modify BleedTestAction
    exec(context)
    {
        if (bleedInput.code == 23700) { player.rpgProfile = nil; return nil; }
        return inherited(context);
    }
;
