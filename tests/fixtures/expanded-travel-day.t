#include "expanded-packing-pace.t"
#include <vhyl-rpg-expanded-development.t>
travelDay: RpgExpandedTravelDay id = 'daily-caravan-travel' profile = crossPhysician approved = true evidence = 'Full daily mileage includes preparation and rest';
travelStudy: RpgExpandedStudy profile = crossPhysician training = packingTraining permitted = true;
travelEquipmentType: object;
travelFamiliarity: RpgExpandedFamiliarity owner = crossPhysician skill = packingCatalogue equipmentType = travelEquipmentType available = true;
travelForagingDay: RpgExpandedForagingDay id = 'gather-all-day' profile = crossPhysician approved = true evidence = 'Dedicate this day to gathering';
modify crossPhysician skills = [packingTraining] developmentOpen = true familiarities = [travelFamiliarity];
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 23900 || code == 23901)
        { local value = travelDay.reserve(); event('test.travel-reserve'); eventValue(value.status); eventValue(value.reason);
          if (code == 23901) throw new RpgError(); return nil; }
        if (code == 23902)
        { local value = travelStudy.assess(1); event('test.travel-study'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 23903)
        { local value = travelFamiliarity.assess(1); event('test.travel-familiarity'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 23904) { rpgSpendTime(86400); return nil; }
        if (code == 23905) { travelForagingDay.reserve(); return nil; }
        if (code == 23906)
        { local value = travelForagingDay.assess(); event('test.travel-forage'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 23907)
        { event('test.travel-state'); eventValue(crossPhysician.travelDays.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        return inherited(context);
    }
;
