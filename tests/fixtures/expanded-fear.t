#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
fearRoom: Room 'Echo Chamber';
fearRules: RpgExpandedRules scaledInjuryShock = true;
fearProfile: RpgExpandedProfile rules = fearRules;
fearContext: RpgExpandedFearContext profile = fearProfile approved = true evidence = 'An extraordinary apparition';
fearEpisode: RpgExpandedFearStun id = 'apparition' context = fearContext approved = true evidence = 'Recorded table outcome';
fearRecovery: RpgExpandedFearStunRecovery id = 'first-recovery' episode = fearEpisode;
fearSecondRecovery: RpgExpandedFearStunRecovery id = 'second-recovery' episode = fearEpisode;
fearFatigue: RpgExpandedFearFatigueLoss id = 'fear-cost' profile = fearProfile;
fearFaintEpisode: RpgExpandedFearFaint id = 'faint-apparition' context = fearContext approved = true evidence = 'Recorded faint outcome';
faintRecovery: RpgExpandedFearFaintRecovery id = 'first-faint-recovery' episode = fearFaintEpisode;
faintRetry: RpgExpandedFearFaintRecovery id = 'second-faint-recovery' episode = fearFaintEpisode;
fearInput: object code = 0 row = 4;
class FearTestAction: Action
    exec(context)
    {
        local code = fearInput.code;
        if (code >= 30)
        {
            if (code == 42) { fearFaintEpisode.tableTotal = fearInput.row; return nil; }
            if (code == 43) { fearRules.scaledInjuryShock = nil; return nil; }
            if (code <= 32)
            {
                local value = code == 31 ? fearFaintEpisode.assess() : fearFaintEpisode.apply();
                event('test.faint-start'); eventValue(value.status); eventValue(value.reason);
                if (code == 32) throw new RpgError(); return nil;
            }
            if (code == 33) { rpgSpendTime(fearInput.row); return nil; }
            if (code == 34) { rpgLiteHealthTime(fearProfile,900); return nil; }
            if (code == 35) { fearProfile.injury = 1; rpgLiteHeal(fearProfile,1); return nil; }
            if (code == 39) { fearProfile.ht = 20; return nil; }
            if (code == 41) { fearProfile.fatigue = fearProfile.maxEnergy * 2; fearProfile.fatigueCollapse = true; return nil; }
            local value = code == 40 ? faintRetry.apply() : code == 37 ? faintRecovery.assess() : faintRecovery.apply();
            event('test.faint-recovery'); eventValue(value.status); eventValue(value.reason);
            if (code == 38) throw new RpgError(); return nil;
        }
        if (code >= 20)
        {
            if (code == 23) { fearProfile.fatigue = 9; return nil; }
            if (code == 24) { fearProfile.fatigue = 10; return nil; }
            if (code == 25) { fearProfile.fatigue = 19; return nil; }
            if (code == 26) { fearProfile.fatigue = 20; fearProfile.becomeUnconscious(); return nil; }
            if (code == 27) { fearRules.scaledInjuryShock = nil; return nil; }
            fearFatigue.amount = fearInput.row;
            local value = code == 21 ? fearFatigue.assess() : fearFatigue.apply();
            event('test.fear-fatigue'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.fatigueAdded); eventValue(value.injuryAdded);
            if (code == 22) throw new RpgError(); return nil;
        }
        if (code <= 2)
        {
            fearEpisode.tableTotal = fearInput.row;
            local value = code == 1 ? fearEpisode.assess() : fearEpisode.apply();
            event('test.fear-start'); eventValue(value.status); eventValue(value.reason);
            if (code == 2) throw new RpgError(); return nil;
        }
        if (code == 3) { rpgSpendTime(1); return nil; }
        if (code == 4) { rpgLiteRecoverStun(fearProfile); return nil; }
        if (code == 8) { fearProfile.willAdjustment = 10; return nil; }
        if (code == 9) { fearContext.isolated = true; return nil; }
        if (code == 10) { fearContext.isolated = nil; return nil; }
        if (code == 11) { fearProfile.willAdjustment = -7; return nil; }
        if (code == 12)
        {
            local retry = fearSecondRecovery.apply();
            event('test.fear-recovery'); eventValue(retry.status); eventValue(retry.reason);
            eventValue(retry.check == nil ? nil : retry.check.score);
            return nil;
        }
        local value = code == 6 ? fearRecovery.assess() : fearRecovery.apply();
        event('test.fear-recovery'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.check == nil ? nil : value.check.score);
        if (code == 7) throw new RpgError(); return nil;
    }
;
fearAction: FearTestAction;
fearVerb: Verb code = 2250 action = fearAction label = 'fear operation';
modify gameMain initialRoom = fearRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2250) { fearInput.code = args[1]; fearInput.row = args[2]; return vhylAct(verb,args); }
    if (verb == 2251)
    {
        event('test.fear-state'); eventValue(fearProfile.mentalStun ? 1 : 0); eventValue(fearEpisode.completed ? 1 : 0);
        eventValue(fearEpisode.initialEnd); eventValue(fearEpisode.recoveries.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2263)
    {
        event('test.fear-fatigue-state'); eventValue(fearProfile.fatigue); eventValue(fearProfile.injury);
        eventValue(fearProfile.unconscious ? 1 : 0); eventValue(fearProfile.expandedWounds.length());
        eventValue(fearProfile.fearFatigueLosses.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2266)
    {
        event('test.faint-state'); eventValue(fearProfile.unconscious ? 1 : 0); eventValue(fearProfile.posture);
        eventValue(fearFaintEpisode.nextCheckAt); eventValue(fearFaintEpisode.completedAt);
        eventValue(fearProfile.fearFaints.length()); eventValue(fearFaintEpisode.recoveries.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2267)
    {
        event('test.faint-injury'); eventValue(fearProfile.injury); eventValue(fearProfile.expandedWounds.length());
        eventValue(fearFaintEpisode.onset == nil || fearFaintEpisode.onset.check == nil ? nil : fearFaintEpisode.onset.check.roll);
        eventValue(fearFaintEpisode.nextCheckAt); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return nil;
}
