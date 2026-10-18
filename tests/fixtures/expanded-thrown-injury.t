#include "expanded-thrown-damage.t"
thrownPerson: RpgExpandedProfile rules = bleedRules;
throwInjury: RpgExpandedThrownInjury id = 'target-impact' receipt = thrownDamage approved = true
    evidence = 'The confirmed hit strikes an ordinary humanoid torso with the declared protection' dropDestination = bleedRoom;
throwInjuryDuplicate: RpgExpandedThrownInjury id = 'target-impact-again' receipt = thrownDamage approved = true
    evidence = 'A second ID cannot apply this side of the receipt again' dropDestination = bleedRoom;
throwSelfInjury: RpgExpandedThrownInjury id = 'thrown-person-impact' receipt = thrownDamage side = 'object' approved = true
    evidence = 'The represented thrown person suffers the independent ordinary torso impact' dropDestination = bleedRoom;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1230)
        { local value = throwInjury.assess(); event('test.thrown-injury-preview'); eventValue(value.status); eventValue(value.reason); eventValue(rpgRandom.draws); return nil; }
        if (code == 1231 || code == 1232)
        { throwInjury.apply(); if (code == 1232) throw new RpgError(); return nil; }
        if (code == 1233)
        {
            event('test.thrown-injury'); eventValue(catchProfile.injury); eventValue(thrownPerson.injury);
            eventValue(catchProfile.thrownInjuries.length()); eventValue(thrownPerson.thrownInjuries.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1234)
        {
            event('test.thrown-injury-duplicate');
            try { eventValue(throwInjuryDuplicate.apply().status); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 1235) { throwInjury.flexibleDR = 9; return nil; }
        if (code == 1236) { throwInjury.outerDR = 2; return nil; }
        if (code == 1237) { thrownDamage.objectKind = 'character'; thrownDamage.objectProfile = thrownPerson; return nil; }
        if (code == 1238) { throwSelfInjury.apply(); return nil; }
        if (code == 1239) { throwInjury.location = 'face'; return nil; }
        if (code == 1240)
        {
            event('test.thrown-protection');
            foreach (local row in [[14,'cr',4,10],[15,'cr',4,10],[25,'cut',5,10],[14,'cut',4,10],
                [25,'imp',5,10],[25,'pi',5,10],[14,'cr',14,10]])
            {
                local value = rpgExpandedAssessThrownProtection(row[1],row[2],row[3],row[4]);
                eventValue(value.penetratingDamage); eventValue(value.bluntInjury); eventValue(value.healthLoss);
            }
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
