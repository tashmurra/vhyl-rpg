#include "expanded-mortal-stabilization.t"
traumaCare: RpgExpandedTraumaMaintenance id = 'support' patient = bleedProfile caregiver = surgicalHealer
    skill = surgicalPhysician approved = true equipmentEvidence = 'Continuous oxygen and transfusion support with a trained caregiver';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 190)
        {
            surgicalHealer.skills = [surgicalTraining,surgicalPhysicianTraining];
            mortalRollInput.rolls = [11,7,10]; traumaCare.start(); return nil;
        }
        if (code == 191) { traumaCare.lifeSupport = true; return nil; }
        if (code == 192) { rpgSpendTime(1800); return nil; }
        if (code == 193) { rpgSpendTime(86400); return nil; }
        if (code == 194) { traumaCare.end(); return nil; }
        if (code == 195)
        {
            event('test.trauma-maintenance'); eventValue(bleedProfile.dead ? 1 : 0);
            eventValue(bleedProfile.mortal ? 1 : 0); eventValue(bleedProfile.mortalClock);
            eventValue(traumaCare.checks.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(traumaCare.endedAt); return nil;
        }
        if (code == 196) { traumaCare.assess(); return nil; }
        if (code == 197) { rpgSpendTime(3600); throw new RpgError(); }
        if (code == 198) { surgicalPhysician.techLevel = 5; return nil; }
        if (code == 199) { rpgLiteRest(bleedProfile,3600,nil,nil,nil,nil); return nil; }
        return inherited(context);
    }
;
