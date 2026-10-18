#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-hazards.t>
hazardRoom: Room 'Shelter';
modify gameMain initialRoom = hazardRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 1800)
    {
        local context = new RpgExpandedInfectionContext(); context.infectedMatter = args[2] == 1;
        context.specialLocale = args[3] == 1; context.antibiotics = args[4] == 1;
        context.medicalTL = args[5]; context.criticalTreatmentFailure = args[6] == 1;
        context.untreatedDirtyWound = args[7] == 1;
        local time = rpgLedger.seconds; local draws = rpgRandom.draws;
        local value = args[1] == 0 ? context.assessAcquisition() : context.assessTypicalProgression();
        event('test.infection-context'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.modifier); eventValue(value.checkRequired ? 1 : 0); eventValue(value.prevented ? 1 : 0);
        eventValue(value.intervalSeconds); eventValue(value.failureInjury); eventValue(value.successEndsInfection ? 1 : 0);
        eventValue(rpgLedger.seconds - time); eventValue(rpgRandom.draws - draws); return nil;
    }
    return vhylAct(verb,args);
}
