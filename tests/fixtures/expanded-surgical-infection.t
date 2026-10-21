#include "expanded-surgical-operation.t"
#include <vhyl-rpg-expanded-hazards.t>
surgicalInfectionConditions: RpgExpandedSurgicalInfectionContext medicalTL = 5;
surgicalInfection: RpgExpandedSurgicalInfectionExposure operation = surgicalOperation diseaseId = 'operative-microbe'
    conditions = surgicalInfectionConditions evidence = 'Mandatory acquisition check after this early-antisepsis operation';
modify surgicalOperation infectionExposure = surgicalInfection;
surgicalInfectionDay: RpgExpandedInfectionDay id = 'day-one' exposure = surgicalInfection
    careEvidence = 'A full day with no antibiotics or physician care' medicalTL = 5;
surgicalInfectionNext: RpgExpandedInfectionDay id = 'day-two' exposure = surgicalInfection
    careEvidence = 'A second full day with no antibiotics or physician care' medicalTL = 5;
surgicalRollInput: object rolls = [];
modify rpgRandom
    roll()
    {
        if (surgicalRollInput.rolls.length() > 0)
        {
            local value = surgicalRollInput.rolls[1]; local rest = [];
            for (local index = 2; index <= surgicalRollInput.rolls.length(); index += 1)
                rest = rest + [surgicalRollInput.rolls[index]];
            surgicalRollInput.rolls = rest; self.draws += 3; return value;
        }
        return inherited();
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 160)
        {
            surgicalHealer.skills = [surgicalTraining,surgicalPhysicianTraining];
            surgicalConditions.techLevel = 5; surgicalConditions.earlyAntisepsis = true;
            surgicalRollInput.rolls = [6,14,11,10]; return nil;
        }
        if (code == 161) { rpgSpendTime(86400); return nil; }
        if (code == 162) { surgicalInfectionDay.apply(); return nil; }
        if (code == 163) { surgicalInfectionNext.apply(); return nil; }
        if (code == 164)
        {
            event('test.surgical-infection'); eventValue(surgicalInfection.result == nil ? nil : surgicalInfection.result.infected);
            eventValue(surgicalInfection.days.length()); eventValue(surgicalInfection.ended);
            eventValue(bleedProfile.expandedWounds.length()); eventValue(bleedProfile.injury);
            eventValue(bleedProfile.diseaseInjury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 165) { rpgSpendTime(86400); rpgSpendTime(1); return nil; }
        if (code == 166) { surgicalRollInput.rolls = [6,3]; return nil; }
        return inherited(context);
    }
;
