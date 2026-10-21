#include "expanded-frenzy-voluntary.t"
battleFrenzyEntry: RpgExpandedFrenzyBattleTrigger id = 'battle-entry' profile = fearProfile trait = frenzyTrait
    trigger = voluntaryBattle battle = voluntaryBattle fighter = voluntaryFighter episode = frenzyEpisode firstEntry = true
    evidence = 'This is the character first entry into this encounter' stressRelation = 'unrelated';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1360)
        {
            fearProfile.traits = [frenzyTrait]; frenzyTrait.battleEntry = true; frenzyEpisode.entry = battleFrenzyEntry;
            voluntaryBattle.active = true; voluntaryBattle.order = [voluntaryOther,voluntaryFighter]; return nil;
        }
        if (code == 1361) { fearRules.frenzyBattleEntry = true; return nil; }
        if (code == 1362 || code == 1363)
        { battleFrenzyEntry.resolve(); if (code == 1363) throw new RpgError(); return nil; }
        if (code == 1364) { battleFrenzyEntry.assess(); return nil; }
        if (code == 1365)
        {
            event('test.frenzy-battle'); eventValue(frenzyEpisode.state); eventValue(fearProfile.selfControlTriggers.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1366)
        {
            event('test.frenzy-prices');
            foreach (local rating in [6,9,12,15])
            { local trait = new RpgExpandedFrenzy(); trait.approved = true; trait.selfControlRating = rating;
              eventValue(trait.creationCost()); trait.battleEntry = true; eventValue(trait.creationCost()); }
            return nil;
        }
        return inherited(context);
    }
;
