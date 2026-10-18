#include "expanded-digging-work.t"
teamShovelOne: RpgLiteItem id = 'team-shovel-one';
teamShovelTwo: RpgLiteItem id = 'team-shovel-two';
teamWorkerOne: RpgExpandedProfile rules = bleedRules equipment = [teamShovelOne];
teamWorkerTwo: RpgExpandedProfile rules = bleedRules equipment = [teamShovelTwo];
modify digSite stage = 'ordinary';
modify digHour stage = 'ordinary-pick';
teamWorkOne: RpgExpandedDiggingHour id = 'shoveler-one' profile = teamWorkerOne site = digSite stage = 'loose'
    shovel = teamShovelOne approved = true evidence = 'Owned metal shovel clearing material continuously behind the pick worker';
teamWorkTwo: RpgExpandedDiggingHour id = 'shoveler-two' profile = teamWorkerTwo site = digSite stage = 'loose'
    shovel = teamShovelTwo approved = true evidence = 'A second worker clears with a separate owned metal shovel';
digTeam: RpgExpandedDiggingTeamHour id = 'three-worker-hour' site = digSite members = [teamWorkOne,digHour,teamWorkTwo];
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 640) { digTeam.assess(); return nil; }
        if (code == 641 || code == 642)
        { digTeam.apply(); if (code == 642) throw new RpgError(); return nil; }
        if (code == 643)
        {
            digSite.validate(); event('test.digging-team'); eventValue(digSite.preparedNumerator);
            eventValue(digSite.removedNumerator); eventValue(digSite.rateDenominator);
            eventValue(digSite.hours.length()); eventValue(digSite.teams.length());
            eventValue(bleedProfile.fatigue); eventValue(teamWorkerOne.fatigue); eventValue(teamWorkerTwo.fatigue);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 644) { teamWorkTwo.profile = teamWorkerOne; return nil; }
        if (code == 645) { teamWorkerTwo.equipment = [teamShovelOne]; teamWorkTwo.shovel = teamShovelOne; return nil; }
        if (code == 646) { bleedProfile.st = 9; return nil; }
        if (code == 647) { teamWorkerOne.fatigue = 9; return nil; }
        return inherited(context);
    }
;
