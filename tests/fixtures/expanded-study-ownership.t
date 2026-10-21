#include "expanded-communication-study.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 4100) { gestureRecipient.skills = [learningTraining]; return nil; }
        if (code == 4101) { bleedProfile.skills = [learningTraining,learningTraining]; return nil; }
        if (code == 4102 || code == 4103)
        {
            event('test.study-ownership');
            try
            {
                if (code == 4102) learningStudy.advance(3600); else communicationStudy.apply();
                eventValue('accepted');
            }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(learningStudy.credit); eventValue(learningTraining.points);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
