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
handlingInput: object code = 0;
handlingClockFault: object enabled = nil;
modify rpgLedger
    afterAdvance(previousSeconds)
    {
        inherited(previousSeconds);
        if (handlingClockFault.enabled) trainingAnimal.unconscious = true;
    }
;
class AnimalHandlingAction: Action
    exec(context)
    {
        local code = handlingInput.code;
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
