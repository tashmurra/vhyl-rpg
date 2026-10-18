#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
bleedRoom: Room 'Infirmary';
modify gameMain initialRoom = bleedRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
bleedRules: RpgExpandedRules scaledInjuryShock = true bleeding = true;
bleedProfile: RpgExpandedProfile rules = bleedRules;
bleedWound: RpgExpandedWound id = 'cut' profile = bleedProfile amount = 2;
bleedClassification: RpgExpandedBleedingWound wound = bleedWound damageKind = 'cutting' bleeds = true
    approved = true evidence = 'An open cut from the resolved wound';
bleedEpisode: RpgExpandedBleedingEpisode id = 'cut-bleeding' classification = bleedClassification;
bleedMinute: RpgExpandedBleedingMinute id = 'first-minute' episode = bleedEpisode lossBasis = 2
    approved = true basisEvidence = 'Single untreated two-point injury';
bleedSecond: RpgExpandedBleedingMinute id = 'second-minute' episode = bleedEpisode lossBasis = 2
    approved = true basisEvidence = 'Single untreated two-point injury';
bleedThird: RpgExpandedBleedingMinute id = 'third-minute' episode = bleedEpisode lossBasis = 2
    approved = true basisEvidence = 'Single untreated two-point injury';
bleedInput: object code = 0 forcedRoll = 0;
modify rpgRandom
    roll()
    {
        if (bleedInput.forcedRoll != 0) { self.draws += 3; return bleedInput.forcedRoll; }
        return inherited();
    }
;
class BleedTestAction: Action
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 20)
        {
            if (code == 30) { bleedInput.forcedRoll = 10; return nil; }
            if (code == 31) { bleedInput.forcedRoll = 3; return nil; }
            if (code == 25) { bleedProfile.ht = 20; return nil; }
            if (code == 26) { rpgRandom.seed(5); return nil; }
            if (code == 27) { bleedRules.lastWounds = true; return nil; }
            if (code == 28) { bleedMinute.basisEvidence = nil; return nil; }
            if (code == 29) { bleedProfile.ht = 3; return nil; }
            local request = code == 23 ? bleedSecond : code == 24 ? bleedThird : bleedMinute;
            local value = code == 21 ? request.assess() : request.apply();
            event('test.bleeding-minute'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.injury); eventValue(value.clearMinutes); eventValue(value.stopped ? 1 : 0);
            if (code == 22) throw new RpgError(); return nil;
        }
        if (code == 0) { bleedWound.apply(); return nil; }
        if (code == 4) { rpgSpendTime(60); return nil; }
        if (code == 5) { rpgSpendTime(61); return nil; }
        if (code == 6) { rpgSpendTime(1); return nil; }
        if (code == 7) { bleedRules.bleeding = nil; return nil; }
        if (code == 8) { bleedClassification.damageKind = 'burning'; return nil; }
        if (code == 9) { bleedClassification.exceptionEvidence = 'Authored bleeding exception'; return nil; }
        if (code == 10) { bleedClassification.bleeds = nil; return nil; }
        local value = code == 2 ? bleedEpisode.assess() : bleedEpisode.apply();
        event('test.bleeding-onset'); eventValue(value.status); eventValue(value.reason);
        if (code == 3) throw new RpgError(); return nil;
    }
;
bleedAction: BleedTestAction;
bleedVerb: Verb code = 2285 action = bleedAction label = 'bleeding operation';
act(verb,args)
{
    if (verb == 2285) { bleedInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2286)
    {
        event('test.bleeding-state'); eventValue(bleedProfile.injury);
        eventValue(bleedProfile.bleedingHistory.length()); eventValue(bleedEpisode.startedAt);
        eventValue(bleedEpisode.nextCheckAt); eventValue(bleedProfile.bleedingEpisode == bleedEpisode ? 1 : 0);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2287)
    {
        event('test.bleeding-minute-state'); eventValue(bleedProfile.injury);
        eventValue(bleedProfile.expandedWounds.length()); eventValue(bleedEpisode.minutes.length());
        eventValue(bleedEpisode.clearMinutes); eventValue(bleedEpisode.stoppedAt);
        eventValue(bleedEpisode.nextCheckAt); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    return vhylAct(verb,args);
}
