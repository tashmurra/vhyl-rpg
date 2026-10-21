#include "expanded.t"
lieSkill: RpgExpandedLieDetectionSkill;
lieTraining: RpgTraining skill = lieSkill points = 4;
lieObserver: RpgExpandedProfile rules = expandedRules skills = [lieTraining];
lieSubject: RpgExpandedProfile rules = expandedRules;
lieReading: RpgExpandedLieDetection id = 'alibi' observer = lieObserver subject = lieSubject skill = lieSkill
    statement = 'The witness claims to have stayed home' truthKnown = true subjectLying = true approved = true
    evidence = 'Known scene facts and ordinary same-species interaction without empathy traits';
modify rpgRandom
    lieFailure = nil
    lieRolls = 0
    roll()
    {
        self.draws += 3; self.lieRolls += 1;
        return self.lieRolls == 1 ? (self.lieFailure ? 18 : 3) : (self.lieFailure ? 3 : 18);
    }
;
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 18400 || code == 18401)
        {
            local value = lieReading.apply();
            event('test.lie-result'); eventValue(value.status); eventValue(value.conclusion);
            if (code == 18401) throw new RpgError(); return nil;
        }
        if (code == 18402) { rpgRandom.lieFailure = true; return nil; }
        if (code == 18403) { lieReading.failureConclusion = 'truthful'; return nil; }
        if (code == 18404)
        {
            local value = lieReading.assess(); event('test.lie-assessment'); eventValue(value.status);
            eventValue(value.observerScore); eventValue(value.subjectScore); return nil;
        }
        if (code == 18405) { lieReading.empathyModifier = 3; lieReading.easyToRead = true; lieReading.speciesModifier = -2; return nil; }
        if (code == 18406)
        {
            event('test.lie-state'); eventValue(lieObserver.lieDetections.length()); eventValue(rpgRandom.draws);
            eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
