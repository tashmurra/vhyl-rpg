#include "expanded-learning-bar.t"
modify learningBar mitigated = true;
learningOtherOwner: RpgLiteProfile;
learningSecondSlot: RpgTraining skill = learningSkill points = 1;
learningReservation: object active = nil;
modify bleedProfile
    developmentSpendingReason() { return learningReservation.active ? 'authored-reservation' : inherited(); }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 5100) { learningOtherOwner.skills = [learningTraining]; return nil; }
        if (code == 5101) { bleedProfile.skills = [learningTraining,learningSecondSlot]; return nil; }
        if (code == 5102) { learningReservation.active = true; return nil; }
        if (code == 5103)
        {
            event('test.learning-direct'); eventValue(rpgLiteLearn(bleedProfile,learningSkill,2,nil) ? 1 : 0);
            eventValue(learningTraining.points); eventValue(learningSecondSlot.points); eventValue(bleedProfile.unspentPoints);
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
