#include "expanded-surgical-operation.t"
#include <vhyl-rpg-expanded-traits.t>
#include <vhyl-rpg-expanded-hazards.t>
dressingTrait: RpgExpandedPersistentWound approved = true;
modify bleedProfile traits = [dressingTrait];
persistentDressing: RpgExpandedPersistentDressing id = 'daily-dressing' patient = bleedProfile healer = surgicalHealer
    skill = surgicalAid durationSeconds = 60 approved = true evidence = 'Authored sixty-second cleaning and dressing of the opening';
persistentDressingOther: RpgExpandedPersistentDressing id = 'other-dressing' patient = bleedProfile healer = surgicalHealer
    skill = surgicalAid durationSeconds = 60 approved = true evidence = 'A separate dressing attempt';
dressingInfectionConditions: RpgExpandedInfectionContext untreatedDirtyWound = true plagueRidden = true medicalTL = 8;
dressingExposure: RpgExpandedInfectionExposure wound = bleedWound conditions = dressingInfectionConditions
    diseaseId = 'dressing-microbe' evidence = 'A separately observed dirty wound in a plague-ridden area';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 230) { persistentDressing.assess(); return nil; }
        if (code == 231 || code == 232)
        { persistentDressing.apply(); if (code == 232) throw new RpgError(); return nil; }
        if (code == 233) { rpgSpendTime(86340); return nil; }
        if (code == 234) { persistentDressingOther.apply(); return nil; }
        if (code == 235)
        {
            event('test.persistent-dressing'); eventValue(bleedProfile.persistentWoundDressedToday() ? 1 : 0);
            eventValue(bleedProfile.persistentWoundInfectionModifier(true)); eventValue(bleedProfile.persistentWoundInfectionModifier(nil));
            eventValue(bleedProfile.injury); eventValue(bleedProfile.persistentDressings.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 236)
        {
            local value = dressingExposure.assess(); event('test.dressing-infection');
            eventValue(value.status); eventValue(rpgLiteScore(bleedProfile,value.context)); return nil;
        }
        if (code == 237) { bleedInput.forcedRoll = 17; return nil; }
        return inherited(context);
    }
;
