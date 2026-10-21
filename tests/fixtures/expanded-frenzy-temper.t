#include "expanded-volatile-temper.t"
temperFrenzyTrait: RpgExpandedFrenzy approved = true;
temperFrenzyEpisode: RpgExpandedFrenzyEpisode id = 'temper-response' profile = fearProfile trait = temperFrenzyTrait
    entry = temperFrenzyEntry approved = true evidence = 'Failed temper starts the owned frenzy episode';
temperFrenzyEntry: RpgExpandedFrenzyTemperEntry profile = fearProfile trait = temperFrenzyTrait
    temper = temperTrigger episode = temperFrenzyEpisode;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1340) { fearProfile.traits = [temperTrait,temperFrenzyTrait]; return nil; }
        if (code == 1341) { temperTrigger.frenzyEntry = temperFrenzyEntry; return nil; }
        if (code == 1342)
        {
            event('test.frenzy-temper'); eventValue(temperFrenzyEpisode.state);
            eventValue(fearProfile.frenzyEpisodes.length()); eventValue(fearProfile.selfControlTriggers.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1343) { temperFrenzyEntry.commit(temperTrigger); return nil; }
        if (code == 1344) { temperFrenzyEntry.temper = nil; temperTrigger.assess(); return nil; }
        return inherited(context);
    }
;
