#include "expanded-fear-event.t"
modify rpgRandom die() { self.draws += 1; return 1; };
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 420 || code == 421)
        {
            fearFaintEpisode.tableTotal = 20; fearFaintEpisode.id = 'apparition';
            fearFaintEpisode.recoveryPolicy = code == 420 ? 'automatic' : 'health-minute';
            fearEventInput.initialRoll = 17; fearEventInput.tableRoll = 13; return nil;
        }
        if (code == 422) { ownedFearEvent.applyConsequence(fearFaintEpisode); return nil; }
        if (code == 423)
        {
            event('test.shock-faint'); eventValue(fearProfile.fearFaints.length()); eventValue(fearProfile.fatigue);
            eventValue(fearProfile.injury); eventValue(fearProfile.unconscious ? 1 : 0);
            eventValue(fearFaintEpisode.nextCheckAt); eventValue(fearFaintEpisode.completedAt);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 424) { fearFaintEpisode.recoveryPolicy = nil; fearFaintEpisode.apply(); return nil; }
        return inherited(context);
    }
;
