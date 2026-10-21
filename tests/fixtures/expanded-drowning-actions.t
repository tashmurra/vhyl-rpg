#include "expanded-drowning-care.t"
#include <vhyl-dialogue.t>
modify player rpgProfile = drowningHealer;
careStartAction: RpgExpandedDrowningCareAction attempt = drowningCare;
careFinishAction: RpgExpandedDrowningCareAction attempt = drowningCare operation = 'finish';
careCancelAction: RpgExpandedDrowningCareAction attempt = drowningCare operation = 'cancel'
    cancellationEvidence = 'Rescuer must withdraw';
careRollbackAction: RpgExpandedDrowningCareAction attempt = drowningCare
    perform(actor) { inherited(actor); throw new RpgError(); }
;
careStartVerb: Verb code = 17710 action = careStartAction label = 'start-care';
careFinishVerb: Verb code = 17711 action = careFinishAction label = 'finish-care';
careCancelVerb: Verb code = 17712 action = careCancelAction label = 'cancel-care';
careRollbackVerb: Verb code = 17713 action = careRollbackAction label = 'rollback-care';
grammar command(careStartCmd): 'start' 'care' : Command action = careStartAction;
grammar command(careFinishCmd): 'finish' 'care' : Command action = careFinishAction;
grammar command(careCancelCmd): 'cancel' 'care' : Command action = careCancelAction;
grammar command(careRollbackCmd): 'rollback' 'care' : Command action = careRollbackAction;
careHelper: Actor 'helper' location(swimRoom) vocab = 'helper';
carePlan: Conversation id = 'care-plan' target = careHelper
    choices = [careStartChoice,careFinishChoice,careCancelChoice,careRollbackChoice];
class CareRouteChoice: DialogueChoice
    careAction = nil
    selected(context) { return self.careAction.perform(context.asker); }
;
careStartChoice: CareRouteChoice id = 'start' labelId = 'care.start' careAction = careStartAction;
careFinishChoice: CareRouteChoice id = 'finish' labelId = 'care.finish' careAction = careFinishAction;
careCancelChoice: CareRouteChoice id = 'cancel' labelId = 'care.cancel' careAction = careCancelAction;
careRollbackChoice: CareRouteChoice id = 'rollback' labelId = 'care.rollback' careAction = careRollbackAction;
careStartLabel: Message id = 'care.start' text = 'Start rescue treatment';
careFinishLabel: Message id = 'care.finish' text = 'Complete rescue treatment';
careCancelLabel: Message id = 'care.cancel' text = 'Withdraw from treatment';
careRollbackLabel: Message id = 'care.rollback' text = 'Exercise treatment rollback';
modify SwimFixtureAction
    exec(context)
    {
        if (swimInput.code == 17700) { rpgRandom.exhaustionRoll = 3; return nil; }
        if (swimInput.code == 17701) { player.rpgProfile = nil; return nil; }
        if (swimInput.code == 17702)
        {
            event('test.care-action-state'); eventValue(drowningCare.startedAt != nil); eventValue(drowningCare.cancelledAt != nil);
            eventValue(swimSubmersion.resuscitations.length()); eventValue(swimPatient.airClock);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
