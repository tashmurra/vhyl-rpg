#include "expanded-motion-trait.t"
motionTrip: RpgExpandedMotionJourney id = 'crossing' profile = motionHero seagoing = true
    approved = true evidence = 'Continuous moving ferry crossing';
motionCause: RpgExpandedRetchingContext profile = motionHero approved = true evidence = 'Motion-induced vomiting';
motionVomit: RpgExpandedRetching id = 'day-one-vomit' context = motionCause approved = true
    evidence = 'First day vomiting' oralEffectsReviewed = true;
motionVomitTwo: RpgExpandedRetching id = 'day-two-vomit' context = motionCause approved = true
    evidence = 'Second day vomiting' oralEffectsReviewed = true;
motionDayOne: RpgExpandedMotionDay journey = motionTrip episode = motionVomit;
motionDayTwo: RpgExpandedMotionDay journey = motionTrip day = 2 episode = motionVomitTwo;
modify rpgRandom
    journeyRoll = 9
    roll() { self.draws += 3; return self.journeyRoll; }
;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 16200 || code == 16201)
        { motionDayOne.apply(); if (code == 16201) throw new RpgError(); return nil; }
        if (code == 16202)
        {
            event('test.motion-journey'); eventValue(motionTrip.days.length()); eventValue(motionTrip.currentPenalty);
            eventValue(rpgRandom.draws); eventValue(motionHero.retchingEpisode != nil); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 16203) { rpgSpendTime(86400); motionDayTwo.apply(); return nil; }
        if (code == 16204) { rpgRandom.journeyRoll = 16; return nil; }
        if (code == 16205) { motionTrip.endEvidence = 'Disembarked'; motionTrip.end(); return nil; }
        if (code == 16206)
        { local value = motionDayOne.assess(); event('test.motion-preview'); eventValue(value.status); eventValue(rpgRandom.draws); return nil; }
        return inherited(context);
    }
;
