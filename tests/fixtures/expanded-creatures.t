#include <vhyl.h>
#include <vhyl.t>
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
modify gameMain initialRoom = creatureRoom;
startup() { return vhylStart(); }
act(verb,args)
{
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
