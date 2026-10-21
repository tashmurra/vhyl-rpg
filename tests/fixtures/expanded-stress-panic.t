#include "expanded-timed-panic-path.t"
#include <vhyl-rpg-expanded-traits.t>
#include <vhyl-rpg-expanded-stress.t>
panicStressPolicy: RpgExpandedStressPolicy;
panicStress: RpgExpandedStressState profile = positionHero policy = panicStressPolicy;
panicStressGain: RpgExpandedStressGain id = 'first-reminder' cause = 'first-reminder' state = panicStress severity = 'severe' evidence = 'Explicit authored reminder';
panicStressSecond: RpgExpandedStressGain id = 'second-reminder' cause = 'second-reminder' state = panicStress severity = 'severe' evidence = 'A distinct authored reminder';
panicStressRecovery: RpgExpandedFearPanicRecovery id = 'strained-recovery' episode = timedPathEpisode;
modify PositionTestAction
    exec(context)
    {
        if (positionInput.code == 820) { panicStress.configure(); panicStressGain.apply(); panicStressSecond.apply(); return nil; }
        if (positionInput.code == 821)
        { event('test.stress-panic'); eventValue(panicStress.balance); eventValue(panicStress.pending().threshold); return nil; }
        if (positionInput.code == 822)
        {
            local choice = new RpgExpandedStressResolution(); choice.decision = panicStress.pending();
            choice.choice = 'strain'; choice.evidence = 'Resolve the pending threshold as strain'; choice.apply();
            rpgSpendTime(timedPathEpisode.nextCheckAt-rpgLedger.seconds); panicStressRecovery.apply();
            event('test.stress-panic-recovery'); eventValue(panicStressRecovery.result.check.score); return nil;
        }
        return inherited(context);
    }
;
