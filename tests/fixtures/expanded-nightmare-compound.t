#include "expanded-fear-mental-compound.t"
compoundNightmares: RpgExpandedNightmares approved = true selfControlRating = 6;
compoundNightmareDay: object;
compoundNightmareControl: RpgExpandedSelfControlTrigger id = 'compound-nightmare-control' profile = fearProfile
    trait = compoundNightmares trigger = 'first-morning' evidence = 'The first morning after an actual sleep period';
compoundNightmareWaking: RpgExpandedNightmareWaking id = 'compound-nightmare-morning' profile = fearProfile
    control = compoundNightmareControl day = compoundNightmareDay dayEndsAt = 86400 morningConfirmed = true
    evidence = 'The following morning belongs to this explicitly bounded campaign day';
compoundNightmareRecovery: RpgExpandedFearFaintRecovery id = 'compound-nightmare-recovery' episode = compoundFaint;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 970)
        {
            compoundFear.tableTotal = 27; compoundFear.episode = compoundFaint; compoundFear.acquisition = compoundMentalAward;
            compoundMentalAward.trait = compoundNightmares; compoundMentalAward.tableTotal = 23;
            fearProfile.creationComplete = true; fearProfile.disadvantageLimit = 0;
            fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; fearEventInput.initialRoll = 3; return nil;
        }
        if (code == 971)
        { local v = compoundNightmareWaking.apply(); event('test.compound-nightmare-waking');
          eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 972)
        { rpgSpendTime(60); compoundNightmareRecovery.apply(); return nil; }
        if (code == 973 || code == 975)
        {
            rpgLiteRest(fearProfile,28800,true,true,true,nil); fearEventInput.tableRoll = 18;
            compoundNightmareWaking.apply(); if (code == 975) throw new RpgError(); return nil;
        }
        if (code == 974)
        {
            event('test.compound-nightmare'); eventValue(fearProfile.fearBeliefCompounds.length());
            eventValue(fearProfile.traits.length()); eventValue(fearProfile.unconscious ? 1 : 0);
            eventValue(fearProfile.nightmareWakings.length()); eventValue(fearProfile.fatigue); eventValue(fearProfile.sleepDebt);
            eventValue(rpgRandom.draws); eventValue(fearProfile.earnedPoints); eventValue(fearProfile.unspentPoints);
            eventValue(fearProfile.nightmareShaking() ? 1 : 0); return nil;
        }
        return inherited(context);
    }
;
