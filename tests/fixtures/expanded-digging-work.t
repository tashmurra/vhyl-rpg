#include "expanded-bleeding.t"
#include <vhyl-rpg-expanded-exploration.t>
digShovel: RpgLiteItem id = 'shovel';
digPick: RpgLiteItem id = 'pick';
modify bleedProfile equipment = [digShovel,digPick];
digSite: RpgExpandedDiggingSite id = 'excavation' capacityCubicFeet = 80;
digHour: RpgExpandedDiggingHour id = 'first-hour' profile = bleedProfile site = digSite shovel = digShovel pick = digPick
    approved = true evidence = 'The owned tools are serviceable metal digging tools and the site is accessible throughout the hour';
digSecond: RpgExpandedDiggingHour id = 'second-hour' profile = bleedProfile site = digSite shovel = digShovel pick = digPick
    approved = true evidence = 'A second uninterrupted hour at the same accessible site';
digThird: RpgExpandedDiggingHour id = 'third-hour' profile = bleedProfile site = digSite shovel = digShovel pick = digPick
    approved = true evidence = 'A proposed third hour';
digHourInput: object request = digHour;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 610) { digHourInput.request.assess(); return nil; }
        if (code == 611 || code == 612)
        { digHourInput.request.apply(); if (code == 612) throw new RpgError(); return nil; }
        if (code == 613)
        {
            event('test.digging-work'); eventValue(digSite.removedNumerator); eventValue(digSite.rateDenominator);
            eventValue(digSite.hours.length()); eventValue(bleedProfile.diggingHours.length());
            eventValue(bleedProfile.fatigue); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 614) { digHourInput.request = digSecond; return nil; }
        if (code == 615) { digSite.stage = 'ordinary'; return nil; }
        if (code == 616) { digSite.stage = 'hard-solo'; return nil; }
        if (code == 617) { digHourInput.request.toolMaterial = 'wood'; return nil; }
        if (code == 618) { bleedProfile.equipment = []; return nil; }
        if (code == 619) { bleedProfile.fatigue = 9; return nil; }
        if (code == 620) { bleedProfile.st = 11; return nil; }
        if (code == 621) { digHourInput.request = digThird; return nil; }
        return inherited(context);
    }
;
