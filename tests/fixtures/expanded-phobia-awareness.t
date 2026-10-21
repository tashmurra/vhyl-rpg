#include "expanded-phobia.t"
phobiaLongFaint: RpgExpandedFearFaint id = 'phobia-first' context = phobiaFirstContext tableTotal = 19
    approved = true evidence = 'The owned phobia check selected the long faint';
phobiaPause: RpgExpandedPhobiaAwarenessPause id = 'unconscious' exposure = phobiaExposure approved = true
    evidence = 'The faint prevents conscious perception of the stimulus';
longFaintRecovery: RpgExpandedFearFaintRecovery id = 'wake' episode = phobiaLongFaint;
modify rpgRandom die() { self.draws += 1; return 6; };
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 460) { fearEventInput.initialRoll = 13; fearEventInput.tableRoll = 18; return nil; }
        if (code == 461) { phobiaFirst.applyConsequence(phobiaLongFaint); return nil; }
        if (code == 462 || code == 463) { phobiaPause.begin(); if (code == 463) throw new RpgError(); return nil; }
        if (code == 464) { rpgSpendTime(720); return nil; }
        if (code == 465) { fearEventInput.tableRoll = 3; longFaintRecovery.apply(); return nil; }
        if (code == 466 || code == 467)
        { phobiaPause.resume(true,'The awake character sees the still-present stimulus'); if (code == 467) throw new RpgError(); return nil; }
        if (code == 468)
        {
            event('test.phobia-awareness'); eventValue(phobiaExposure.awarenessPaused() ? 1 : 0);
            eventValue(phobiaExposure.nextCheckAt()); eventValue(phobiaExposure.checks.length());
            eventValue(fearProfile.unconscious ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
