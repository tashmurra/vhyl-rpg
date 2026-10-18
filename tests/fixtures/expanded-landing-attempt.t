#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-exploration.t>
landingOccurrence: object;
landingAcrobatics: RpgLiteSkill id = 'acrobatics' attribute = rpgDX difficulty = 2 defaultPenalty = -6;
landingSwimming: RpgLiteSkill id = 'swimming' attribute = rpgHT difficulty = 0 defaultPenalty = -4;
landingAcroTraining: RpgTraining skill = landingAcrobatics points = 12;
landingSwimTraining: RpgTraining skill = landingSwimming points = 16;
modify bleedProfile skills = [landingAcroTraining,landingSwimTraining];
landingAttempt: RpgExpandedLandingAttempt id = 'landing' profile = bleedProfile fall = landingOccurrence
    distance = 17 skill = landingAcrobatics freeToMove = true approved = true
    evidence = 'One free-moving humanoid fall at ordinary gravity; choose the maneuver before rolling';
landingDuplicate: RpgExpandedLandingAttempt id = 'another-choice' profile = bleedProfile fall = landingOccurrence
    distance = 17 method = 'dive' fluid = true skill = landingSwimming freeToMove = true approved = true
    evidence = 'A second maneuver for the same occurrence must be rejected';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 860)
        { local value = landingAttempt.assess(); event('test.landing-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.score); eventValue(value.modifier); return nil; }
        if (code == 861 || code == 862)
        { landingAttempt.resolve(); if (code == 862) throw new RpgError(); return nil; }
        if (code == 863)
        {
            event('test.landing-owned'); eventValue(bleedProfile.landingAttempts.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            if (landingAttempt.result != nil)
            { eventValue(landingAttempt.result.effectiveDistance); eventValue(landingAttempt.result.velocity); eventValue(landingAttempt.result.negatesDamage ? 1 : 0); }
            return nil;
        }
        if (code == 864) { landingDuplicate.resolve(); return nil; }
        if (code == 865) { landingAttempt.method = 'dive'; landingAttempt.fluid = true; landingAttempt.skill = landingSwimming; return nil; }
        if (code == 866) { bleedInput.forcedRoll = 9; return nil; }
        if (code == 867) { landingAttempt.freeToMove = nil; return nil; }
        return inherited(context);
    }
;
