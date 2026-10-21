#include "expanded-nature-observation.t"
#include <vhyl-rpg-expanded-social.t>
natureKnowledge: RpgExpandedKnowledge owner = bleedProfile;
modify bleedProfile knowledge = natureKnowledge;
natureDisclosure: RpgExpandedNatureDisclosure id = 'plant-finding' assessment = natureObservation recipient = bleedProfile;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 20400 || code == 20401)
        { local value = natureDisclosure.deliver(); event('test.nature-disclosure'); eventValue(value.status); eventValue(value.reason); eventValue(value.statements);
          if (code == 20401) throw new RpgError(); return nil; }
        if (code == 20402)
        { event('test.nature-knowledge'); eventValue(natureKnowledge.received.length()); eventValue(natureKnowledge.beliefs.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 20403)
        {
            natureObservation.result.check.achieved = nil;
            try { bleedProfile.validateFeatures(); }
            catch (RpgExpandedError error) { event('test.nature-history-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
