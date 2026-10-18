#include "expanded.t"
reserveTrait: RpgExpandedBreathReserveTrait level = 2 approved = true eligibility = 'nonhuman'
    evidence = 'Authored amphibious ancestry has exceptional air storage';
reserveHero: RpgExpandedProfile rules = expandedRules traits = [reserveTrait];
purchasedReserve: RpgExpandedBreathReserve id = 'purchased-reserve' profile = reserveHero usePurchasedReserve = true
    controlSucceeded = true evidence = 'Prepared mild activity with established breathing skill success';
modify ExpandedTestAction
    exec(context)
    {
        local code = expandedInput.code;
        if (code == 18200)
        {
            purchasedReserve.start();
            event('test.reserve-trait'); eventValue(reserveTrait.creationCost()); eventValue(purchasedReserve.reserveLevels);
            eventValue(purchasedReserve.durationSeconds); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 18201) { reserveTrait.mitigated = true; return nil; }
        if (code == 18202 || code == 18203)
        {
            if (code == 18202) reserveTrait.eligibility = 'ordinary-human';
            else reserveHero.traits = [reserveTrait,reserveTrait];
            try { reserveHero.purchasedBreathReserveLevels(); }
            catch (RpgExpandedError error) { event('test.reserve-trait-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 18204)
        {
            local copy = rpgExpandedCopyTemplateTrait(reserveTrait); copy.level = 3;
            event('test.reserve-trait-copy'); eventValue(copy != reserveTrait); eventValue(reserveTrait.level);
            eventValue(copy.creationCost()); eventValue(copy.eligibility); eventValue(copy.evidence == reserveTrait.evidence); return nil;
        }
        return inherited(context);
    }
;
