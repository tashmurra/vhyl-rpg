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
        if (code == 23908 || code == 23909)
        { travelDay.interrupt('The caravan stops for other activities'); if (code == 23909) throw new RpgError(); return nil; }
        if (code == 23910) { rpgSpendTime(1); return nil; }
        if (code == 23911)
        { event('test.travel-mileage'); eventValue(travelDay.fullMileageReason()); eventValue(travelDay.interruptedAt); return nil; }
        if (code == 23912)
        {
            travelDay.interruptedAt += 1;
            try { travelDay.validateBinding(); }
            catch (RpgExpandedError error) { event('test.travel-interruption-error'); eventValue(error.reason); }
            return nil;
        }
        if (code == 23913)
        {
            event('test.travel-overlap');
            eventValue(crossPhysician.nonTravelScheduleReason(0,1));
            eventValue(crossPhysician.nonTravelScheduleReason(1,1));
            eventValue(crossPhysician.foragingDayConflict(0));
            return nil;
        }
        if (code == 23914)
        {
            local value = travelDay.interrupt('The caravan stops for other activities');
            event('test.travel-interrupt'); eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 23915)
        {
            local value = packWalk.assessFullDayPace(packRoute,[100],[travelDay]);
            event('test.travel-full-pace'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.milesHundredths); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
