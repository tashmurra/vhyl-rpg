#include "expanded-psychology-assessment.t"
psychologySecondSubject: RpgExpandedProfile rules = healthRules;
psychologyGroup: object;
modify psychologyContext subject = nil group = psychologyGroup members = [psychologySubject,psychologySecondSubject]
    smallGroupApproved = true evidence = 'Two members of the same species form a small group suitable for this prediction';
modify psychologyAssessment finding = 'The pair will probably leave together when the crowd arrives';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 21200 || code == 21201 || code == 21202)
        {
            if (code == 21200) psychologyContext.smallGroupApproved = nil;
            if (code == 21201) psychologyContext.members = [psychologySubject,psychologySubject];
            if (code == 21202) psychologyContext.knownWell = true;
            try { psychologyContext.validatePsychology(); }
            catch (RpgExpandedError error) { event('test.psychology-group-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 21203)
        {
            psychologyContext.members = [psychologySecondSubject,psychologySubject];
            try { psychologyAssessment.resolve(); }
            catch (RpgExpandedError error) { event('test.psychology-group-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
