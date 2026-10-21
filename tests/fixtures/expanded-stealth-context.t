#include "expanded-shadowing-context.t"
modify crossPhysician st = 10 equipment = [];
stealthLoad: RpgLiteItem id = 'stealth-load' weight = 2500;
stealthCatalogue: RpgExpandedStealthSkill;
stealthContextFixture: RpgExpandedStealthContext skill = stealthCatalogue hiding = true approved = true
    evidence = 'The authored hiding place and observer conditions apply';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 29300)
        { event('test.stealth-score'); eventValue(rpgLiteScore(crossPhysician,stealthContextFixture)); eventValue(crossPhysician.encumbrance());
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 29301) { crossPhysician.dx = 8; return nil; }
        if (code == 29302) { stealthContextFixture.naturalCover = 'none'; return nil; }
        if (code == 29303) { stealthContextFixture.naturalCover = 'many'; stealthContextFixture.coverBonus = 3; return nil; }
        if (code == 29304) { stealthContextFixture.bareRoom = true; return nil; }
        if (code == 29305)
        { stealthContextFixture.hiding = nil; stealthContextFixture.movingSilently = true; stealthContextFixture.fasterThanMoveOne = true; return nil; }
        if (code == 29306) { stealthContextFixture.scentObserver = beggingObserver; beggingObserver.traits = [fineSmellFixture]; return nil; }
        if (code == 29307) { fineSmellFixture.mitigated = true; return nil; }
        if (code == 29308) { stealthContextFixture.coverBonus = 2; rpgLiteScore(crossPhysician,stealthContextFixture); return nil; }
        if (code == 29309) { crossPhysician.equipment = [stealthLoad]; return nil; }
        return inherited(context);
    }
;
