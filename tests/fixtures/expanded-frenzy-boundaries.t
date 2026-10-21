#include "expanded-frenzy-turn.t"
#include <vhyl-rpg-expanded-tactical.t>
burstMode: RpgLiteAttackMode ranged = true base = 'fixed' dice = 1 rof = 3 capacity = 3 reloadSeconds = 3 maximumRange = 100;
burstWeapon: RpgLiteWeapon id = 'burst-weapon' modes = [burstMode] ready = true ammunition = 3 reserves = 3;
burstChoice: RpgExpandedRageRangedChoice fighter = turnFighter target = turnTarget action = 'attack'
    firearm = true shots = 3 distanceYards = 21 approved = true evidence = 'Visible foe at twenty-one yards, full burst';
reloadChoice: RpgExpandedRageRangedChoice fighter = turnFighter action = 'reload' firearm = true distanceYards = 21
    quickDrawConfirmed = true reloadSeconds = 1 approved = true evidence = 'Recorded successful quick draw and one-second magazine change';
reloadManeuver: RpgExpandedFrenzyManeuver kind = 'ready' option = 'reload' turn = reloadTurn;
reloadTurn: RpgExpandedFrenzyTurn id = 'reload' episode = frenzyEpisode battle = turnBattle fighter = turnFighter
    choice = reloadChoice maneuver = reloadManeuver approved = true evidence = 'Reload with the remaining magazine';
boundOrigin: RpgExpandedHex;
boundEast: RpgExpandedHex q = 1;
boundFar: RpgExpandedHex q = 2;
boundCell: RpgExpandedHexTerrain coordinate = boundOrigin;
boundEastCell: RpgExpandedHexTerrain coordinate = boundEast;
boundFarCell: RpgExpandedHexTerrain coordinate = boundFar;
boundMap: RpgExpandedTacticalMap id = 'corridor' cells = [boundCell,boundEastCell,boundFarCell];
boundFigure: RpgExpandedTacticalFigure id = 'actor' profile = fearProfile;
boundTarget: RpgExpandedTacticalFigure id = 'target' profile = turnTargetProfile;
boundPlace: RpgExpandedTacticalPlacement id = 'actor-arrival' map = boundMap figure = boundFigure
    coordinate = boundOrigin facing = 0 approved = true evidence = 'Actor at corridor entrance';
boundTargetPlace: RpgExpandedTacticalPlacement id = 'target-arrival' map = boundMap figure = boundTarget
    coordinate = boundFar facing = 3 approved = true evidence = 'Target two yards away';
boundLeg: RpgExpandedPathLeg destination = boundEast;
boundPath: RpgExpandedMovementPath figure = boundFigure move = 5 maneuver = 'move-attack' legs = [boundLeg];
boundPosition: RpgExpandedFrenzyPath owner = frenzyTurn path = boundPath uninterrupted = true evidence = 'Clear uninterrupted one-yard approach';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1500)
        {
            fearProfile.equipment = [burstWeapon]; turnFighter.weapon = burstWeapon;
            frenzyTurn.choice = burstChoice; turnManeuver.kind = 'attack'; turnManeuver.option = nil; return nil;
        }
        if (code == 1501) { turnBattle.index = 2; return nil; }
        if (code == 1502 || code == 1503) { reloadTurn.apply(); if (code == 1503) throw new RpgError(); return nil; }
        if (code == 1504)
        {
            event('test.frenzy-boundaries'); eventValue(burstWeapon.ammunition); eventValue(burstWeapon.reserves);
            eventValue(turnTargetProfile.injury); eventValue(frenzyEpisode.turns.length());
            eventValue(boundFigure.coordinate == nil ? -1 : boundFigure.coordinate.q);
            eventValue(frenzyEpisode.attackFriends ? 1 : 0); eventValue(fearProfile.unconscious ? 1 : 0);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1505)
        {
            boundPlace.apply(); boundTargetPlace.apply(); turnChoice.inReach = nil;
            turnChoice.action = 'move-attack'; turnChoice.movementAssessed = true; turnChoice.moveAttackPossible = true;
            turnChoice.distanceYards = 2; turnChoice.closestDistance = 1; turnChoice.endingDistance = 1; turnChoice.movement = 1;
            turnManeuver.kind = 'move-attack'; turnManeuver.option = nil; turnManeuver.movement = 1;
            frenzyTurn.position = boundPosition; return nil;
        }
        if (code == 1506) { turnManeuver.movement = 0; frenzyTurn.apply(); throw new RpgError(); }
        if (code == 1507)
        { frenzyExit.occasion = 'no-foes'; frenzyExit.downed = nil; frenzyExit.noFoesEvidence = 'All hostile participants have left'; return nil; }
        if (code == 1508) { frenzyTurn.targetKind = 'friend'; return nil; }
        if (code == 1509) { fearProfile.injury = 10; fearProfile.unconscious = true; return nil; }
        if (code == 1510)
        {
            fearProfile.ht = 3; fearProfile.injury = 40; frenzyExitHealth.approved = true;
            frenzyExitHealth.consciousnessRuling = 'fail'; frenzyExitHealth.evidence = 'Recorded unrollable consciousness ruling'; return nil;
        }
        return inherited(context);
    }
;
