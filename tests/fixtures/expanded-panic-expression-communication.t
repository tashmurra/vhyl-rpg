#include "expanded-panic-crying.t"
#include <vhyl-rpg-expanded-characters.t>
#include <vhyl-rpg-expanded-traits.t>
expressionSpeechLoss: RpgExpandedSpeechLimitation approved = true;
expressionSpeechAcquisition: RpgExpandedFearPhysicalAcquisition id = 'speech-loss' eventId = 'earlier-fear'
    profile = bleedProfile purchases = [expressionSpeechLoss] approved = true
    evidence = 'The author selected loss of articulated speech after an earlier fear event';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10730) { bleedProfile.creationComplete = true; expressionSpeechAcquisition.apply(); return nil; }
        if (code == 10731)
        { expressionSpeechLoss.total = true; expressionSpeechLoss.points = -25; bleedProfile.traits = [expressionSpeechLoss]; return nil; }
        if (code == 10732)
        {
            event('test.expression-communication'); eventValue(bleedProfile.speechLimitationLevel());
            eventValue(bleedProfile.fearPhysicalAcquisitions.length());
            eventValue(bleedProfile.healthEffortReason('talk',nil,true,nil)); return nil;
        }
        if (code == 10733)
        { expressionActivity.mode = 'gesture'; expressionGate.requiresMovement = true; return nil; }
        return inherited(context);
    }
;
