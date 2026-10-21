#include "expanded-bleeding.t"
forageCompanion: RpgExpandedProfile rules = bleedRules;
forageOccurrence: object;
foragePoison: RpgExpandedForagePoisoning id = 'berries' occurrence = forageOccurrence
    forager = bleedProfile party = [bleedProfile,forageCompanion] approved = true ordinarySusceptibility = true
    evidence = 'Recorded plant forage result; ordinary susceptible recipients consumed the food';
forageDuplicate: RpgExpandedForagePoisoning id = 'berries-again' occurrence = forageOccurrence
    forager = bleedProfile party = [bleedProfile,forageCompanion] approved = true ordinarySusceptibility = true
    evidence = 'Same consumed batch';
forageRolls: object rolls = [10,11] index = 1;
modify rpgRandom
    roll() { local result = forageRolls.rolls[forageRolls.index]; forageRolls.index += 1; self.draws += 3; return result; }
    die() { self.draws += 1; return 4; }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1500 || code == 1501)
        { foragePoison.foragingCheck = rpgCheck(12,code == 1500 ? 17 : 18); forageDuplicate.foragingCheck = foragePoison.foragingCheck; return nil; }
        if (code == 1502)
        { local value = foragePoison.assess(); event('test.forage-poison-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 1503 || code == 1504)
        { foragePoison.apply(); if (code == 1504) throw new RpgError(); return nil; }
        if (code == 1505)
        {
            event('test.forage-poison-owned'); eventValue(bleedProfile.injury); eventValue(forageCompanion.injury);
            eventValue(bleedProfile.foragePoisonings.length()); eventValue(forageCompanion.foragePoisonings.length());
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1506)
        {
            event('test.forage-poison-duplicate');
            try { forageDuplicate.apply(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 1507) { foragePoison.ordinarySusceptibility = nil; return nil; }
        return inherited(context);
    }
;
