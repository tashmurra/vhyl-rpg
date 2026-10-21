#include "expanded-psychology-context.t"
#include <vhyl-rpg-expanded-social.t>
psychologySituation: object;
psychologyAssessment: RpgExpandedPsychologyAssessment id = 'departure-prediction' profile = crossPhysician context = psychologyContext
    situation = psychologySituation approved = true evidence = 'Observed conduct supports a bounded prediction in this situation'
    finding = 'The traveler is likely to leave when the crowd arrives';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 21000 || code == 21001)
        { local value = psychologyAssessment.resolve(); event('test.psychology-finding'); eventValue(value.status); eventValue(value.finding);
          if (code == 21001) throw new RpgError(); return nil; }
        if (code == 21002)
        { event('test.psychology-history'); eventValue(crossPhysician.psychologyAssessments.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 21003) { rpgRandom.medicalRoll = 18; return nil; }
        if (code == 21004)
        { local value = psychologyAssessment.assess(); event('test.psychology-preview'); eventValue(value.status); eventValue(value.score); eventValue(value.finding); return nil; }
        if (code == 21005)
        {
            psychologyContext.knownWell = true;
            try { psychologyAssessment.resolve(); }
            catch (RpgExpandedError error) { event('test.psychology-binding'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
