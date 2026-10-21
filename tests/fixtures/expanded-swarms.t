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
turn(tokens) { return rpgDispatchTurn(tokens); }
#include <vhyl-rpg-expanded-health.t>
swarmRules: RpgExpandedRules scaledInjuryShock = true;
modify trainingAnimal rules = swarmRules;
combatSwarm: RpgExpandedSwarm;
combatExposure: RpgExpandedSwarmExposure swarm = combatSwarm victim = trainingAnimal tiny = true
    approved = true evidence = 'Uncovered target in swarm contact';
combatSwarmAttack: RpgExpandedSwarmAttack id = 'contact-one' exposure = combatExposure
    inContact = true approved = true distanceFromNest = 0 evidence = 'Same victim in contact at the nest';
swarmActionInput: object code = 0;
counterShield: RpgLiteItem id = 'small-shield' db = 1 ready = true;
counterRequest: RpgExpandedSwarmCounterattack id = 'counter-one' swarm = combatSwarm actor = trainingAnimal
    inReach = true ableToStomp = true approved = true evidence = 'Able combatant adjacent to the swarm';
class SwarmTestAction: Action
    exec(context)
    {
        local code = swarmActionInput.code;
        if (code >= 20)
        {
            if (code == 23) { counterRequest.kind = 'shield'; counterRequest.shield = counterShield; trainingAnimal.equipment = [counterShield]; }
            if (code == 24 || code == 28 || code == 29) combatSwarm.kind = 'ground-biters';
            if (code == 25) counterShield.ready = nil;
            local request = counterRequest;
            if (code == 26 || code == 27)
            {
                if (code == 26) rpgSpendTime(1);
                request = new RpgExpandedSwarmCounterattack(); request.id = rpgLedger.seconds + 100;
                request.swarm = combatSwarm; request.actor = trainingAnimal; request.kind = counterRequest.kind;
                request.shield = counterRequest.shield; request.inReach = true; request.ableToStomp = true;
                request.approved = true; request.evidence = 'Continuing counterattack';
            }
            local value = code == 21 || code == 28 ? request.assess() : request.apply();
            event('test.swarm-counter'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.injury); eventValue(value.dispersed ? 1 : 0);
            if (code == 22 || code == 29) throw new RpgError(); return nil;
        }
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
    if (verb == 2222) { swarmActionInput.code = 20 + args[1]; return rpgDispatchAction(2220,args); }
    if (verb == 2223)
    {
        event('test.swarm-counter-state'); eventValue(combatSwarm.injury); eventValue(combatSwarm.dispersed ? 1 : 0);
        eventValue(combatSwarm.counterattacks.length()); eventValue(trainingAnimal.swarmCounterattacks.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2224)
    {
        event('test.diffuse'); eventValue(rpgExpandedDiffuseInjury(args[1],args[2],args[3] != 0));
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2220) { swarmActionInput.code = args[1]; return rpgDispatchAction(verb,[]); }
    if (verb == 2221)
    {
        event('test.swarm-health'); eventValue(trainingAnimal.injury); eventValue(trainingAnimal.expandedWounds.length());
        eventValue(combatSwarm.attacks.length()); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return nil;
}
