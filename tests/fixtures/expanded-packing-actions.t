#include "expanded-packing-disclosure.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = crossPhysician;
packingAssessAction: RpgExpandedPackingAction attempt = packingAttempt;
packingReceiveAction: RpgExpandedPackingAction attempt = packingAttempt disclosure = packingDisclosure operation = 'receive';
packingRollbackAction: RpgExpandedPackingAction attempt = packingAttempt
    perform(actor) { inherited(actor); throw new RpgError(); }
;
packingAssessVerb: Verb code = 22810 action = packingAssessAction label = 'plan-route';
packingReceiveVerb: Verb code = 22811 action = packingReceiveAction label = 'receive-finding';
packingRollbackVerb: Verb code = 22812 action = packingRollbackAction label = 'rollback-assessment';
grammar command(packingAssessCmd): 'plan' 'route' : Command action = packingAssessAction;
grammar command(packingReceiveCmd): 'receive' 'finding' : Command action = packingReceiveAction;
grammar command(packingRollbackCmd): 'rollback' 'assessment' : Command action = packingRollbackAction;
packingGuide: Actor 'guide' location(healthRoom) vocab = 'guide';
packingConversation: Conversation id = 'packing-plan' target = packingGuide choices = [packingAssessChoice,packingReceiveChoice,packingRollbackChoice];
class PackingRouteChoice: DialogueChoice
    packingAction = nil
    selected(context) { return self.packingAction.perform(context.asker); }
;
packingAssessChoice: PackingRouteChoice id = 'assess' labelId = 'packing.assess' packingAction = packingAssessAction;
packingReceiveChoice: PackingRouteChoice id = 'receive' labelId = 'packing.receive' packingAction = packingReceiveAction;
packingRollbackChoice: PackingRouteChoice id = 'rollback' labelId = 'packing.rollback' packingAction = packingRollbackAction;
packingAssessLabel: Message id = 'packing.assess' text = 'Plan the route';
packingReceiveLabel: Message id = 'packing.receive' text = 'Receive the finding';
packingRollbackLabel: Message id = 'packing.rollback' text = 'Exercise assessment rollback';
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 22800) { player.rpgProfile = nil; return nil; }
        return inherited(context);
    }
;
