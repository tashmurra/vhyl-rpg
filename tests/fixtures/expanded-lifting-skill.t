#include "expanded-equipment-lift.t"
liftingSkill: RpgLiteSkill id = 'lifting' attribute = rpgHT difficulty = 1;
liftingTraining: RpgTraining skill = liftingSkill points = 16;
modify bleedProfile skills = [liftingTraining];
liftingAttempt: RpgExpandedLiftingSkillAttempt id = 'crate-technique' profile = bleedProfile skill = liftingSkill
    lift = liftOperation approved = true evidence = 'Apply trained lifting technique to this specific pickup';
liftingDuplicate: RpgExpandedLiftingSkillAttempt id = 'another-technique-roll' profile = bleedProfile skill = liftingSkill
    lift = liftOperation approved = true evidence = 'The same physical pickup';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 750 || code == 751)
        { liftingAttempt.resolve(); if (code == 751) throw new RpgError(); return nil; }
        if (code == 752)
        {
            event('test.lifting-skill'); eventValue(bleedProfile.liftingSkillAttempts.length());
            eventValue(liftingAttempt.result == nil ? nil : liftingAttempt.result.score);
            eventValue(liftingAttempt.result == nil ? nil : liftingAttempt.result.liftNumerator);
            eventValue(liftingAttempt.result == nil ? nil : liftingAttempt.result.liftDenominator);
            eventValue(bleedProfile.basicLiftHundredths()); eventValue(bleedProfile.loadHundredths());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 753) { liftingTraining.points = 0; return nil; }
        if (code == 754) { bleedInput.forcedRoll = 17; return nil; }
        if (code == 755) { liftingDuplicate.resolve(); return nil; }
        if (code == 756) { liftingAttempt.assess(); return nil; }
        return inherited(context);
    }
;
