#include "expanded-lie-detection.t"
lieKnowledge: RpgExpandedKnowledge owner = lieObserver;
modify lieObserver knowledge = lieKnowledge;
lieDisclosure: RpgExpandedLieDetectionDisclosure id = 'alibi-impression' assessment = lieReading recipient = lieObserver
    lyingStatement = 'The alibi seems false' truthfulStatement = 'The alibi seems credible' uncertainStatement = 'You cannot judge the alibi';
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 18500 || code == 18501)
        {
            local value = lieDisclosure.deliver(); event('test.lie-disclosure'); eventValue(value.status); eventValue(value.statements);
            if (code == 18501) throw new RpgError(); return nil;
        }
        if (code == 18502)
        {
            event('test.lie-knowledge'); eventValue(lieKnowledge.beliefs.length()); eventValue(lieKnowledge.received.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 18503)
        {
            local value = lieDisclosure.assess(); event('test.lie-disclosure-preview'); eventValue(value.status);
            eventValue(value.statements.length()); return nil;
        }
        if (code == 18504)
        {
            lieReading.result.conclusion = 'truthful';
            try { lieDisclosure.deliver(); }
            catch (RpgExpandedError error) { event('test.lie-disclosure-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
