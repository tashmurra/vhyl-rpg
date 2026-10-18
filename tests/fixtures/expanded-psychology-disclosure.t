#include "expanded-psychology-assessment.t"
psychologyKnowledge: RpgExpandedKnowledge owner = crossPhysician;
modify crossPhysician knowledge = psychologyKnowledge;
psychologyDisclosure: RpgExpandedPsychologyDisclosure id = 'received-prediction' assessment = psychologyAssessment recipient = crossPhysician;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 21100 || code == 21101)
        { local value = psychologyDisclosure.deliver(); event('test.psychology-disclosure'); eventValue(value.status); eventValue(value.reason); eventValue(value.statements);
          if (code == 21101) throw new RpgError(); return nil; }
        if (code == 21102)
        { event('test.psychology-knowledge'); eventValue(psychologyKnowledge.received.length()); eventValue(psychologyKnowledge.beliefs.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 21103)
        {
            psychologyDisclosure.completedAt += 1;
            try { psychologyDisclosure.deliver(); }
            catch (RpgExpandedError error) { event('test.psychology-disclosure-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 21104)
        { local value = psychologyDisclosure.assess(); event('test.psychology-disclosure-preview'); eventValue(value.status); eventValue(value.statements.length()); return nil; }
        return inherited(context);
    }
;
