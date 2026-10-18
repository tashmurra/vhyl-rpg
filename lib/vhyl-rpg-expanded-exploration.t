/* Include after the expanded foundation. Source: full-2008, B346. */

/** Pure task-time assessment. Positive steps select 2/4/8/15/30 times normal;
 * negative steps remove 10% each. The caller must authorize applicability. */
class RpgExpandedTaskTime: object
    baseSeconds = 1
    steps = 0
    applicable = nil
    combat = nil
    assess(rules)
    {
        rpgInteger(self.baseSeconds, 1, 1000000); rpgInteger(self.steps, -10, 5);
        local result = new RpgExpandedResult();
        if (self.steps != 0 && (!self.applicable || self.combat))
        { result.reason = 'task-time-inapplicable'; return result; }
        if (self.steps == -10 && !rules.cinematicInstantTasks)
        { result.reason = 'instant-task-disabled'; return result; }
        result.status = 'ready'; result.modifier = self.steps;
        result.seconds = self.steps >= 0
            ? self.baseSeconds * [1,2,4,8,15,30][self.steps + 1]
            : (self.baseSeconds * (10 + self.steps) + 9) / 10;
        return result;
    }
;
