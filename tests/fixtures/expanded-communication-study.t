#include "expanded-gesture-exchange.t"
modify speechLimitation total = true points = -25;
communicationStudy: RpgExpandedCommunicationStudy
    id = 'gesture-study' source = gestureExchange study = learningStudy approved = true
    evidence = 'The practiced skill covers the gestures used in this exchange'
;
communicationDuplicate: RpgExpandedCommunicationStudy
    id = 'other-credit' source = gestureExchange study = learningStudy approved = true
    evidence = 'The same interval cannot be credited twice'
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 4000 || code == 4001 || code == 4002 || code == 4008)
        {
            local value = code == 4000 ? communicationStudy.assess()
                : code == 4008 ? communicationDuplicate.apply() : communicationStudy.apply();
            event('test.communication-study'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.points); eventValue(value.seconds);
            if (code == 4002) throw new RpgError(); return nil;
        }
        if (code == 4003)
        {
            event('test.communication-study-state'); eventValue(learningStudy.credit);
            eventValue(learningStudy.awarded); eventValue(learningTraining.points);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(gestureExchange.creditedStudy == communicationStudy ? 1 : 0); return nil;
        }
        if (code == 4004) { learningStudy.credit = 2879960; return nil; }
        if (code == 4005) { communicationStudy.approved = nil; return nil; }
        if (code == 4006) { speechLimitation.mitigated = true; return nil; }
        if (code == 4007) { speechLimitation.total = nil; speechLimitation.points = -15; return nil; }
        return inherited(context);
    }
;
