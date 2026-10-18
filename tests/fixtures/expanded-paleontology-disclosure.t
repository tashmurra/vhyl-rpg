#include "expanded-paleontology-assessment.t"
#include <vhyl-rpg-expanded-social.t>
paleontologyKnowledge: RpgExpandedKnowledge owner = crossPhysician;
modify crossPhysician knowledge = paleontologyKnowledge;
paleontologyDisclosure: RpgExpandedPaleontologyDisclosure id = 'received-habitat' assessment = paleontologyAssessment recipient = crossPhysician;
paleontologyOtherObserver: RpgExpandedProfile knowledge = paleontologyOtherKnowledge;
paleontologyOtherKnowledge: RpgExpandedKnowledge owner = paleontologyOtherObserver;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 22000 || code == 22001)
        { local value = paleontologyDisclosure.deliver(); event('test.paleontology-disclosure'); eventValue(value.status); eventValue(value.reason); eventValue(value.statements);
          if (code == 22001) throw new RpgError(); return nil; }
        if (code == 22002)
        { event('test.paleontology-knowledge'); eventValue(paleontologyKnowledge.received.length()); eventValue(paleontologyKnowledge.beliefs.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 22003)
        {
            paleontologyDisclosure.completedAt += 1;
            try { paleontologyDisclosure.deliver(); }
            catch (RpgExpandedError error) { event('test.paleontology-disclosure-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 22004)
        { local value = paleontologyDisclosure.assess(); event('test.paleontology-disclosure-preview'); eventValue(value.status); eventValue(value.statements.length()); return nil; }
        if (code == 22005)
        {
            crossPhysician.knowledge = paleontologyOtherKnowledge;
            try { paleontologyDisclosure.deliver(); }
            catch (RpgExpandedError error) { event('test.paleontology-disclosure-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
