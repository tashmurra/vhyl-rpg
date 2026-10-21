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
        if (code == 757) { liftOperation.skillAttempt = liftingAttempt; liftCrate.weight = 18000; return nil; }
        if (code == 758) { liftCrate.weight = 17000; return nil; }
        if (code == 759)
        { liftingAttempt.resolve(); liftOperation.apply(); throw new RpgError(); }
        if (code == 760)
        { liftOperation.failedAttemptSeconds = 4; liftOperation.failureTimingEvidence = 'This authored unsuccessful strain occupies four seconds'; return nil; }
        if (code == 761 || code == 762)
        { liftOperation.attempt(); if (code == 762) throw new RpgError(); return nil; }
        if (code == 763)
        { local value = liftOperation.assessAttempt(); event('test.lift-attempt-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 764)
        { event('test.lift-attempt-result'); eventValue(liftOperation.result == nil ? nil : liftOperation.result.pickedUp);
          eventValue(liftOperation.result == nil ? nil : liftOperation.result.reason); return nil; }
        if (code == 770) { liftCrate.weight = 2300; return nil; }
        return inherited(context);
    }
;
