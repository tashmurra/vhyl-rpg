#include "expanded-packing-findings.t"
#include <vhyl-rpg-expanded-social.t>
packingKnowledge: RpgExpandedKnowledge owner = crossPhysician;
modify crossPhysician knowledge = packingKnowledge;
packingDisclosure: RpgExpandedPackingDisclosure id = 'received-route' attempt = packingAttempt recipient = crossPhysician;
packingOtherObserver: RpgExpandedProfile knowledge = packingOtherKnowledge;
packingOtherKnowledge: RpgExpandedKnowledge owner = packingOtherObserver;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 22700 || code == 22701)
        { local value = packingDisclosure.deliver(); event('test.packing-disclosure'); eventValue(value.status); eventValue(value.reason); eventValue(value.statements);
          if (code == 22701) throw new RpgError(); return nil; }
        if (code == 22702)
        { event('test.packing-knowledge'); eventValue(packingKnowledge.received.length()); eventValue(packingKnowledge.beliefs.length()); eventValue(rpgRandom.draws); return nil; }
        if (code == 22703)
        {
            packingDisclosure.completedAt += 1;
            try { packingDisclosure.deliver(); }
            catch (RpgExpandedError error) { event('test.packing-disclosure-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 22704)
        { local value = packingDisclosure.assess(); event('test.packing-disclosure-preview'); eventValue(value.status); eventValue(value.statements.length()); return nil; }
        if (code == 22705)
        {
            crossPhysician.knowledge = packingOtherKnowledge;
            try { packingDisclosure.deliver(); }
            catch (RpgExpandedError error) { event('test.packing-disclosure-error'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
