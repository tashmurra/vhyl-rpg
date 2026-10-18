#include "expanded-begging-skill.t"
#include <vhyl-rpg-expanded-social.t>
beggingSquare: object;
beggingHour: RpgExpandedBeggingHour id = 'square-hour' profile = crossPhysician context = beggingContext location = beggingSquare
    criticalBonus = 'A resident offers a meal' criticalTrouble = 'A patrol challenges the beggar';
modify crossPhysician money = 0;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 24300 || code == 24301)
        { beggingHour.resolve(); if (code == 24301) throw new RpgError(); return nil; }
        if (code == 24302)
        { local value = beggingHour.assess(); event('test.begging-hour-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 24303)
        { event('test.begging-hour-state'); eventValue(crossPhysician.money); eventValue(rpgLedger.seconds);
          eventValue(rpgRandom.draws); eventValue(crossPhysician.beggingHours.length());
          eventValue(beggingHour.result == nil ? nil : beggingHour.result.incident); return nil; }
        if (code == 24304) { rpgRandom.medicalRoll = 10; return nil; }
        if (code == 24305) { rpgRandom.medicalRoll = 18; return nil; }
        if (code == 24306) { beggingHour.criticalTrouble = nil; return nil; }
        return inherited(context);
    }
;
