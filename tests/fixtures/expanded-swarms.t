#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-creatures.t>
swarmRoom: Room 'Swarm clearing';
trainingAnimal: RpgExpandedProfile;
modify gameMain initialRoom = swarmRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
#include <vhyl-rpg-expanded-health.t>
swarmRules: RpgExpandedRules scaledInjuryShock = true;
modify trainingAnimal rules = swarmRules;
combatSwarm: RpgExpandedSwarm;
combatExposure: RpgExpandedSwarmExposure swarm = combatSwarm victim = trainingAnimal tiny = true
    approved = true evidence = 'Uncovered target in swarm contact';
combatSwarmAttack: RpgExpandedSwarmAttack id = 'contact-one' exposure = combatExposure
    inContact = true approved = true distanceFromNest = 0 evidence = 'Same victim in contact at the nest';
swarmActionInput: object code = 0;
class SwarmTestAction: Action
    exec(context)
    {
        local code = swarmActionInput.code;
        if (code == 4) { combatSwarm.kind = 'ground-biters'; combatExposure.tiny = nil; combatSwarmAttack.distanceFromNest = nil; }
        if (code == 5) { combatExposure.protection = 'clothing'; }
        if (code == 6) combatSwarmAttack.distanceFromNest = 50;
        if (code == 7) rpgSpendTime(1);
        combatExposure.begin();
        local request = combatSwarmAttack;
        if (code == 8 || code == 7)
        {
            request = new RpgExpandedSwarmAttack(); request.id = code == 7 ? 'next-turn' : 'duplicate-turn';
            request.exposure = combatExposure; request.inContact = true; request.approved = true;
            request.distanceFromNest = 0; request.evidence = 'Continuing same contact';
        }
        local value = code == 1 ? request.assess() : request.apply();
        event('test.swarm-attack'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.damage); eventValue(value.injury);
        if (code == 2) throw new RpgError(); return nil;
    }
;
swarmTestAction: SwarmTestAction;
swarmTestVerb: Verb code = 2220 action = swarmTestAction label = 'swarm contact';
act(verb,args)
{
    if (verb == 2220) { swarmActionInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2221)
    {
        event('test.swarm-health'); eventValue(trainingAnimal.injury); eventValue(trainingAnimal.expandedWounds.length());
        eventValue(combatSwarm.attacks.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return nil;
}
