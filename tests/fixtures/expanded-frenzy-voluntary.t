#include "expanded-frenzy-entry.t"
voluntaryOtherProfile: RpgExpandedProfile rules = fearRules;
voluntaryFighter: RpgLiteFighter profile = fearProfile;
voluntaryOther: RpgLiteFighter profile = voluntaryOtherProfile;
voluntaryBattle: RpgLiteBattle fighters = [voluntaryOther,voluntaryFighter];
voluntaryManeuver: RpgExpandedFrenzyConcentrate entry = voluntaryEntry;
voluntaryEntry: RpgExpandedFrenzyVoluntaryEntry id = 'deliberate-entry' profile = fearProfile trait = frenzyTrait
    episode = frenzyEpisode battle = voluntaryBattle fighter = voluntaryFighter maneuver = voluntaryManeuver
    approved = true evidence = 'A complete stationary Concentrate maneuver to enter frenzy';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1350)
        {
            fearProfile.traits = [frenzyTrait]; frenzyEpisode.entry = voluntaryEntry;
            voluntaryBattle.active = true; voluntaryBattle.order = [voluntaryOther,voluntaryFighter];
            voluntaryBattle.index = 2; return nil;
        }
        if (code == 1351 || code == 1352)
        { voluntaryEntry.apply(); if (code == 1352) throw new RpgError(); return nil; }
        if (code == 1353) { voluntaryEntry.assess(); return nil; }
        if (code == 1354)
        {
            event('test.frenzy-voluntary'); eventValue(frenzyEpisode.state);
            eventValue(fearProfile.frenzyVoluntaryEntries.length()); eventValue(voluntaryFighter.concentration);
            eventValue(voluntaryFighter.turnSerial); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1355) { voluntaryBattle.step(voluntaryFighter,voluntaryManeuver); return nil; }
        if (code == 1356) { voluntaryManeuver.movement = 1; voluntaryEntry.assess(); return nil; }
        if (code == 1357) { fearProfile.stunned = true; return nil; }
        return inherited(context);
    }
;
