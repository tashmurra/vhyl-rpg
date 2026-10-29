#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-running.t>
runRoom: Room 'Track';
runRules: RpgExpandedRules;
runHero: RpgExpandedProfile
    actor = player
    rules = runRules
    conditionTicks = 0
    conditionTime(seconds)
    {
        self.conditionTicks += seconds;
        if (self.lingeringSeconds > 0)
        {
            self.lingeringSeconds -= seconds;
            if (self.lingeringSeconds <= 0) { self.lingeringSeconds = 0; self.lingeringPenalty = 0; }
        }
    }
;
runTraining: RpgExpandedTraining skill = rpgExpandedRunningSkill points = 0;
runLoad: RpgLiteItem;
runActivity: RpgExpandedRunning
    profile = runHero
    healthBonus = 0
    skillBonus = 0
    fatigueContext(which)
    {
        local c = inherited(which);
        c.modifier = which == nil ? self.healthBonus : self.skillBonus;
        return c;
    }
;
runLegacy: RpgLiteJourney profile = runHero kind = 'sprint';
runInput: object code = 0 args = [];
runLast: object result = nil reason = nil;
runInit: InitObject execute() { runHero.skills = [runTraining]; runHero.equipment = [runLoad]; };
class RunTestAction: Action
    exec(context)
    {
        local a = runInput.args; local code = runInput.code;
        if (code == 1) rpgRandom.seed(a[2]);
        if (code == 2)
        {
            runHero.ht = a[2]; runHero.dx = a[3]; runHero.fpAdjustment = a[4];
            runHero.willAdjustment = a[5]; runTraining.points = a[6];
        }
        if (code == 3) runLast.result = runActivity.advance(a[2]);
        if (code == 4) runActivity.setPace(a[2]);
        if (code == 5) runActivity.interrupt();
        if (code == 6) runActivity.sprintEligible = a[2] != 0;
        if (code == 7) { runHero.fatigue = a[2]; runHero.injury = a[3]; runHero.restClock = a[4]; }
        if (code == 8) runLast.result = rpgLiteRest(runHero, a[2], nil, nil, nil, nil);
        if (code == 9) { runActivity.advance(a[2]); throw new RpgError(); }
        if (code == 10) { runActivity.healthBonus = a[2]; runActivity.skillBonus = a[3]; }
        if (code == 11) runLoad.weight = a[2];
        if (code == 12) runHero.heatExtra = a[2];
        if (code == 13)
        {
            runLast.reason = nil;
            try { runActivity.setPace(a[2]); }
            catch (RpgExpandedError error) { runLast.reason = error.reason; }
        }
        if (code == 14) { runHero.lingeringPenalty = a[2]; runHero.lingeringSeconds = a[3]; }
        if (code == 15) runLast.result = runLegacy.advance(a[2]);
        if (code == 16) runHero.moveAdjustment = a[2];
        if (code == 17) runHero.posture = a[2];
        if (code == 18) runHero.hunger = a[2];
        return nil;
    }
;
runAction: RunTestAction;
runVerb: Verb code = 700 action = runAction label = 'running-test';
startup() { return vhylStart(); }
modify gameMain initialRoom = runRoom;
act(verb, args)
{
    if (verb == 700) { runInput.code = args[1]; runInput.args = args; return vhylAct(700, []); }
    if (verb == 990)
    {
        event('test.running-state');
        foreach (local value in [runHero.hp(), runHero.fp(), runHero.unconscious, runHero.dead,
            runHero.fatigueCollapse, runHero.restClock, runActivity.elapsed, runActivity.sprintClock,
            runActivity.pacedClock, runActivity.sprintSeconds, runActivity.pace, runActivity.sprintEligible,
            rpgRandom.state, rpgRandom.draws, rpgLedger.seconds, runHero.unconsciousClock,
            runHero.lingeringSeconds, runHero.lingeringPenalty, runHero.conditionTicks]) eventValue(value);
        return nil;
    }
    if (verb == 991)
    {
        local r = runLast.result;
        event('test.running-result');
        foreach (local value in [r.status, r.ofKind(RpgExpandedRunningResult) ? r.reason : nil,
            r.seconds, r.fatigue, r.injury, r.checks.length()]) eventValue(value);
        foreach (local c in r.checks)
        { event('test.running-check'); eventValue(c.score); eventValue(c.roll); eventValue(c.achieved); }
        event('test.running-end'); return nil;
    }
    if (verb == 992)
    {
        local c = runActivity.fatigueContextForCheck();
        event('test.running-preview'); eventValue(runActivity.speedHundredths());
        eventValue(rpgLiteScore(runHero, c)); eventValue(c.skill == nil ? 'ht' : 'running');
        eventValue(runLegacy.speedHundredths()); return nil;
    }
    if (verb == 993) { event('test.running-error'); eventValue(runLast.reason); return nil; }
    return vhylAct(verb, args);
}
