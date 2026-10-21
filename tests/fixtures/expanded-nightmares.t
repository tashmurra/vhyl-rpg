#include "expanded-fear-mental.t"
nightmareTrait: RpgExpandedNightmares approved = true selfControlRating = 6;
nightmareDay: object;
nightmareControl: RpgExpandedSelfControlTrigger id = 'morning-control' profile = fearProfile trait = nightmareTrait
    trigger = 'morning-awakening' evidence = 'The character wakes from the main sleep period';
nightmareWaking: RpgExpandedNightmareWaking id = 'morning' profile = fearProfile control = nightmareControl
    day = nightmareDay dayEndsAt = 86400 morningConfirmed = true evidence = 'The authored waking day ends at second 86400';
nightmareSkill: RpgLiteSkill id = 'authored-skill' attribute = rpgDX difficulty = 1;
nightmareSkillContext: RpgLiteContext skill = nightmareSkill;
nightmarePerContext: RpgLiteContext attribute = rpgPerception;
nightmareIQContext: RpgLiteContext attribute = rpgIQ;
nightmareDuplicateControl: RpgExpandedSelfControlTrigger id = 'duplicate-morning' profile = fearProfile trait = nightmareTrait
    trigger = 'duplicate-awakening' evidence = 'Repeated narration of the same morning';
nightmareDuplicate: RpgExpandedNightmareWaking id = 'duplicate' profile = fearProfile control = nightmareDuplicateControl
    day = nightmareDay dayEndsAt = 86400 morningConfirmed = true evidence = 'The same authored day';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 950)
        { mentalAward.trait = nightmareTrait; fearProfile.creationComplete = true;
          fearProfile.earnedPoints = 9; fearProfile.unspentPoints = 7; return nil; }
        if (code == 951) { fearEventInput.initialRoll = 17; return nil; }
        if (code == 952) { fearEventInput.initialRoll = 3; return nil; }
        if (code == 953 || code == 954)
        { nightmareWaking.apply(); if (code == 954) throw new RpgError(); return nil; }
        if (code == 955)
        { event('test.nightmares'); eventValue(fearProfile.nightmareWakings.length());
          eventValue(fearProfile.fatigue); eventValue(fearProfile.sleepDebt);
          eventValue(fearProfile.healthAttributeModifier(nightmareSkillContext));
          eventValue(fearProfile.healthAttributeModifier(nightmarePerContext));
          eventValue(fearProfile.healthAttributeModifier(nightmareIQContext));
          eventValue(rpgRandom.draws); return nil; }
        if (code == 956) { rpgLiteRest(fearProfile,600,true,true,nil,nil); return nil; }
        if (code == 957) { rpgLiteRest(fearProfile,28800,true,true,true,nil); return nil; }
        if (code == 958) { rpgSpendTime(86400-rpgLedger.seconds); return nil; }
        if (code == 959)
        { local v = nightmareDuplicate.apply(); event('test.nightmare-duplicate'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 960) { nightmareWaking.dayEndsAt = 90000; nightmareWaking.assess(); return nil; }
        if (code == 961) { fearEventInput.initialRoll = 18; return nil; }
        if (code == 962) { fearProfile.fatigue = fearProfile.maxEnergy; return nil; }
        if (code == 963)
        { event('test.nightmare-overflow'); eventValue(fearProfile.injury); eventValue(fearProfile.expandedWounds.length());
          eventValue(fearProfile.nightmareFatigueLosses.length()); return nil; }
        return inherited(context);
    }
;
