#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-creatures.t>
creatureRoom: Room 'Training Yard';
trainingAnimal: RpgExpandedProfile iq = 4;
animalTrainer: RpgExpandedProfile skills = [handlingTraining];
handlingSkill: RpgLiteSkill id = 'animal-handling' attribute = rpgIQ difficulty = 1;
handlingTraining: RpgTraining skill = handlingSkill points = 4;
animalPlan: RpgExpandedAnimalTrainingPlan animal = trainingAnimal trainer = animalTrainer skill = handlingSkill
    appropriateSpecialty = true approved = true level = 4 evidence = 'Suitable canine training and handling specialty';
handlingAttempt: RpgExpandedAnimalHandlingAttempt id = 'yard-command' animal = trainingAnimal handler = animalTrainer
    skill = handlingSkill appropriateSpecialty = true taskId = 'wait-at-gate' trainingEstablished = true familiar = true
    seconds = 30 approved = true available = true uninterrupted = true evidence = 'Trained task in accessible yard';
performanceSkill: RpgLiteSkill id = 'performance' attribute = rpgIQ difficulty = 1;
performanceTraining: RpgTraining skill = performanceSkill points = 8;
animalPerformance: RpgExpandedAnimalPerformance handling = handlingAttempt skill = performanceSkill
    approved = true available = true evidence = 'Entertain the yard audience during this task';
animalOtherPerformance: RpgExpandedAnimalPerformance handling = handlingAttempt skill = performanceSkill
    approved = true available = true evidence = 'Duplicate entertainment check';
animalCourse: RpgExpandedAnimalCourse plan = animalPlan;
animalOtherCourse: RpgExpandedAnimalCourse plan = animalPlan;
animalSessionOne: RpgExpandedAnimalTrainingSession id = 'morning' course = animalCourse
    approved = true uninterrupted = true evidence = 'Two hours of suitable training';
animalSessionTwo: RpgExpandedAnimalTrainingSession id = 'afternoon' course = animalCourse
    approved = true uninterrupted = true evidence = 'Second two-hour training session';
animalSessionOther: RpgExpandedAnimalTrainingSession id = 'other-course' course = animalOtherCourse
    approved = true uninterrupted = true evidence = 'Competing training course';
animalDailyCheck: RpgExpandedAnimalTrainingCheck course = animalCourse approved = true evidence = 'Assess the completed training day';
animalOtherCheck: RpgExpandedAnimalTrainingCheck course = animalCourse approved = true evidence = 'Another daily check';
animalTrainingFailure: RpgExpandedAnimalTrainingFailure attempt = animalDailyCheck classification = 'ordinary'
    approved = true evidence = 'Author classifies this as a day without learning';
animalMilestone: RpgExpandedAnimalTrainingMilestone course = animalCourse approved = true evidence = 'Confirm the completed training objective';
learnedAnimalTask: RpgExpandedAnimalTask id = 'food-recall' requiredLevel = 2 approved = true
    evidence = 'Species-appropriate food recall at general level two';
handlingInput: object code = 0;
handlingClockFault: object enabled = nil;
modify rpgLedger
    afterAdvance(previousSeconds)
    {
        inherited(previousSeconds);
        if (handlingClockFault.enabled) trainingAnimal.unconscious = true;
    }
;
exposureSwarm: object;
exposureRecord: RpgExpandedSwarmExposure swarm = exposureSwarm victim = trainingAnimal tiny = true
    protection = 'clothing' approved = true evidence = 'Tiny insects contacting ordinary clothing';
class AnimalHandlingAction: Action
    exec(context)
    {
        local code = handlingInput.code;
        if (code >= 100)
        {
            if (code == 103) { exposureRecord.protection = 'low-tech-armor'; exposureRecord.armorDR = 5; }
            if (code == 104) { exposureRecord.tiny = nil; exposureRecord.protection = 'normal-armor'; exposureRecord.armorDR = 5; }
            if (code == 105) { exposureRecord.protection = 'special'; exposureRecord.specialEffective = true; }
            if (code == 106) exposureRecord.protection = 'normal-armor';
            if (code == 107) rpgSpendTime(1);
            if (code == 108) exposureRecord.evidence = 'Changed exposure';
            local request = exposureRecord;
            if (code == 109)
            {
                request = new RpgExpandedSwarmExposure(); request.swarm = exposureSwarm;
                request.victim = trainingAnimal; request.approved = true; request.evidence = 'Duplicate contact';
            }
            local value = code == 101 ? request.assess() : request.begin();
            event('test.swarm-protection'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.elapsed); eventValue(value.immune ? 1 : 0); eventValue(value.dr);
            if (code == 102) throw new RpgError(); return nil;
        }
        if (code >= 80)
        {
            if (code == 80 || code == 84)
            {
                trainingAnimal.iq = 5; animalPlan.level = 2;
                local days = 2;
                if (code == 84) { animalPlan.kind = 'trick'; animalPlan.trick = 'retrieve-marked-object'; days = 14; }
                for (local day = 1; day <= days; day += 1)
                {
                    if (day > 1) rpgSpendTime(72000);
                    for (local part = 1; part <= 2; part += 1)
                    {
                        local session = new RpgExpandedAnimalTrainingSession(); session.id = day*2+part;
                        session.course = animalCourse; session.approved = true; session.uninterrupted = true; session.evidence = 'Training session';
                        session.apply();
                    }
                    local daily = new RpgExpandedAnimalTrainingCheck(); daily.course = animalCourse;
                    daily.approved = true; daily.evidence = 'Completed training day'; rpgRandom.seed(1); daily.apply();
                }
                return nil;
            }
            if (code == 90 || code == 91 || code == 92)
            {
                handlingAttempt.trainingEstablished = nil; handlingAttempt.taskDefinition = learnedAnimalTask;
                if (animalPlan.kind == 'trick')
                { learnedAnimalTask.kind = 'trick'; learnedAnimalTask.requiredLevel = nil; learnedAnimalTask.id = animalPlan.trick; }
                handlingAttempt.taskId = learnedAnimalTask.id;
                if (code == 92) learnedAnimalTask.evidence = 'Changed task contract';
                local task = code == 91 ? handlingAttempt.assess() : handlingAttempt.apply();
                event('test.learned-animal-task'); eventValue(task.status); eventValue(task.reason); eventValue(task.score); return nil;
            }
            if (code == 85) animalCourse.successfulDays += 1;
            if (code == 86) animalMilestone.approved = nil;
            if (code == 89) animalMilestone.evidence = 'Changed milestone';
            local value = code == 83 ? animalMilestone.assess() : animalMilestone.apply();
            event('test.animal-milestone'); eventValue(value.status); eventValue(value.reason); eventValue(value.level); eventValue(value.trick);
            if (code == 82) throw new RpgError(); return nil;
        }
        if (code >= 60)
        {
            if (code == 60) { animalSessionOne.apply(); animalSessionTwo.apply(); return nil; }
            if (code == 64) animalDailyCheck.speciesModifier = -5;
            if (code == 65) animalTrainer.iq = 6;
            if (code == 66) trainingAnimal.unconscious = true;
            if (code == 67) animalDailyCheck.evidence = 'Changed daily decision';
            if (code == 69) rpgRandom.seed(5);
            if (code == 70 || code == 71)
            {
                if (code == 71) animalTrainingFailure.classification = 'attack';
                local resolved = animalTrainingFailure.apply();
                event('test.animal-training-failure'); eventValue(resolved.status); eventValue(resolved.reason); return nil;
            }
            local request = code == 68 ? animalOtherCheck : animalDailyCheck;
            local value = code == 63 ? request.assess() : request.apply();
            event('test.animal-daily'); eventValue(value.status); eventValue(value.reason); eventValue(value.score);
            eventValue(value.creditedDays); eventValue(value.failureAdjudicationRequired ? 1 : 0);
            if (code == 62) throw new RpgError(); return nil;
        }
        if (code >= 40)
        {
            if (code == 46) handlingClockFault.enabled = true;
            if (code == 47) rpgLedger.seconds = 80000;
            if (code == 48) animalSessionOne.evidence = 'Changed attendance';
            local request = code == 45 ? animalSessionTwo : code == 44 ? animalSessionOther : animalSessionOne;
            if (code == 49)
            {
                request = new RpgExpandedAnimalTrainingSession(); request.id = 'extra'; request.course = animalCourse;
                request.approved = true; request.uninterrupted = true; request.evidence = 'Extra training';
            }
            local value = code == 43 ? request.assess() : request.apply();
            event('test.animal-session'); eventValue(value.status); eventValue(value.reason); eventValue(value.attendance);
            eventValue(value.dailyCheckRequired ? 1 : 0); eventValue(value.seconds);
            if (code == 42) throw new RpgError(); return nil;
        }
        if (code >= 20)
        {
            if (code == 20 || code == 24)
            {
                animalTrainer.skills = [handlingTraining,performanceTraining];
                if (code == 24) handlingAttempt.familiar = nil;
                handlingAttempt.apply(); return nil;
            }
            if (code == 25) animalPerformance.modifier = -3;
            if (code == 26) animalPerformance.available = nil;
            if (code == 29) animalPerformance.evidence = 'Changed act';
            local request = code == 28 ? animalOtherPerformance : animalPerformance;
            local value = code == 23 ? request.assess() : request.apply();
            event('test.animal-performance'); eventValue(value.status); eventValue(value.reason); eventValue(value.score);
            eventValue(value.succeeded ? 1 : 0); eventValue(value.handlingCheck == nil ? nil : value.handlingCheck.achieved ? 1 : 0);
            if (code == 22) throw new RpgError(); return nil;
        }
        if (code == 4) handlingAttempt.familiar = nil;
        if (code == 5)
        {
            handlingAttempt.mode = 'calm'; handlingAttempt.taskId = nil;
            handlingAttempt.trainingEstablished = nil; handlingAttempt.wild = true;
        }
        if (code == 6) handlingClockFault.enabled = true;
        if (code == 7) handlingAttempt.trainingEstablished = nil;
        if (code == 8) handlingAttempt.performance = true;
        if (code == 9) handlingAttempt.evidence = 'Changed handling request';
        if (code == 10) trainingAnimal.dead = true;
        if (code == 11) { handlingAttempt.stressful = true; handlingAttempt.complexityPenalty = 3; }
        local value = code == 3 ? handlingAttempt.assess() : handlingAttempt.apply();
        event('test.animal-handling'); eventValue(value.status); eventValue(value.reason); eventValue(value.score);
        eventValue(value.succeeded ? 1 : 0); eventValue(value.authorResolutionRequired ? 1 : 0);
        if (code == 2) throw new RpgError(); return nil;
    }
;
animalHandlingAction: AnimalHandlingAction;
animalHandlingVerb: Verb code = 2203 action = animalHandlingAction label = 'handle animal';
modify gameMain initialRoom = creatureRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 2216) { handlingInput.code = 100 + args[1]; return vhylAct(2203,args); }
    if (verb == 2217)
    {
        event('test.swarm-state'); eventValue(exposureRecord.startedAt); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2215)
    {
        local value = rpgExpandedNaturalDamageForStrength(args[1],args[2],args[3],args[4] != 0,args[5] != 0,args[6],args[7]);
        event('test.natural-strength'); eventValue(value.status); eventValue(value.dice); eventValue(value.adds);
        eventValue(value.damageType); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2214)
    {
        local value = rpgExpandedNaturalDamage(args[1],args[2],args[3],args[4],args[5] != 0,args[6] != 0,args[7],args[8]);
        event('test.natural-damage'); eventValue(value.status); eventValue(value.dice); eventValue(value.adds);
        eventValue(value.damageType); eventValue(value.anatomyBonus); eventValue(value.skillBonus);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2213)
    {
        local value = nil;
        if (args[1] == 'domestic') value = rpgExpandedDomesticAnimalValue(args[2],args[3],args[4]);
        if (args[1] == 'enhanced') value = rpgExpandedEnhancedAnimalValue(args[2],args[3],args[4],args[5]);
        if (args[1] == 'move') value = rpgExpandedMountMoveValue(args[2],args[3]);
        if (args[1] == 'war') value = rpgExpandedWarTrainingValue(args[2],args[3] != 0);
        event('test.animal-value'); eventValue(value.status); eventValue(value.reason); eventValue(value.numerator);
        eventValue(value.denominator); eventValue(value.money); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2211) { handlingInput.code = 80 + args[1]; return vhylAct(2203,args); }
    if (verb == 2212)
    {
        event('test.animal-milestone-state'); eventValue(trainingAnimal.animalTrainingLevel);
        eventValue(trainingAnimal.animalKnownTricks.length()); eventValue(trainingAnimal.animalTrainingMilestones.length());
        eventValue(animalCourse.successfulDays); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2209) { handlingInput.code = 60 + args[1]; return vhylAct(2203,args); }
    if (verb == 2210)
    {
        event('test.animal-daily-state'); eventValue(animalCourse.successfulDays); eventValue(animalCourse.pendingDay);
        eventValue(animalCourse.pendingFailure == nil ? 0 : 1); eventValue(animalCourse.checks.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2207) { handlingInput.code = 40 + args[1]; return vhylAct(2203,args); }
    if (verb == 2208)
    {
        event('test.animal-session-state'); eventValue(animalCourse.sessions.length());
        eventValue(trainingAnimal.animalTrainingSessions.length()); eventValue(animalCourse.successfulDays);
        eventValue(animalCourse.pendingDay); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2205) { handlingInput.code = 20 + args[1]; return vhylAct(2203,args); }
    if (verb == 2206)
    {
        event('test.animal-performance-state'); eventValue(handlingAttempt.performanceReceipt == nil ? 0 : 1);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2203) { handlingInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2204)
    {
        event('test.animal-handling-state'); eventValue(trainingAnimal.animalHandlingAttempts.length());
        eventValue(trainingAnimal.injury); eventValue(animalTrainer.injury); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2200)
    {
        event('test.animal-days'); eventValue(rpgExpandedAnimalTrainingDays(args[1],args[2]));
        eventValue(rpgExpandedAnimalTrickDays(args[1])); return nil;
    }
    if (verb == 2201)
    {
        event('test.animal-modifiers'); eventValue(rpgExpandedAnimalTaskModifier(args[1] != 0,args[2] != 0,args[3]));
        eventValue(rpgExpandedAnimalCalmingModifier(args[4] != 0,args[5] != 0,args[6] != 0));
        eventValue(rpgExpandedAnimalCombatPenalty(args[7])); return nil;
    }
    if (verb == 2202)
    {
        local code = args[1];
        if (code == 1) animalPlan.wild = true;
        if (code == 2) animalPlan.appropriateSpecialty = nil;
        if (code == 3) animalTrainer.skills = [];
        if (code == 4) trainingAnimal.iq = 3;
        if (code == 5) { animalPlan.kind = 'trick'; animalPlan.trick = 'retrieve-marked-object'; }
        if (code == 6) trainingAnimal.iq = 6;
        local value = animalPlan.assess(); event('test.animal-plan'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.days); eventValue(value.modifier); eventValue(value.dailySeconds);
        eventValue(value.sessionsPerDay); eventValue(value.sessionSeconds); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return vhylAct(verb,args);
}
