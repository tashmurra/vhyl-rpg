#include "expanded-makeup-equipment.t"
availabilitySkill: RpgExpandedSkill id = 'availability-example' attribute = rpgIQ difficulty = 0 defaultPenalty = -4;
availabilityContext: RpgExpandedSkillContext skill = availabilitySkill;
legacyAvailabilityContext: RpgLiteContext skill = availabilitySkill;
modify PhysicianFixtureAction
    exec(context)
    {
        if (healthInput.code == 26600)
        {
            event('test.task-availability'); eventValue(availabilityContext.taskUnavailableReason(crossPhysician));
            eventValue(availabilityContext.unavailableReason(crossPhysician));
            eventValue(legacyAvailabilityContext.unavailableReason(crossPhysician));
            eventValue(rpgLiteScore(crossPhysician,availabilityContext));
            eventValue(makeupContextFixture.taskUnavailableReason(crossPhysician));
            eventValue(rpgLiteScore(crossPhysician,makeupContextFixture));
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
