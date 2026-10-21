#include "expanded-frenzy-entry.t"
#include <vhyl-rpg-expanded-combat.t>
turnTargetProfile: RpgExpandedProfile rules = fearRules;
turnMode: RpgLiteAttackMode ranged = nil base = 'fixed' dice = 1 damageType = 'cr';
turnWeapon: RpgLiteWeapon id = 'club' modes = [turnMode] ready = true;
turnFighter: RpgLiteFighter profile = fearProfile weapon = turnWeapon;
turnTarget: RpgLiteFighter profile = turnTargetProfile;
turnBattle: RpgLiteBattle fighters = [turnTarget,turnFighter];
turnChoice: RpgExpandedRageMeleeChoice fighter = turnFighter target = turnTarget action = 'all-out-attack'
    inReach = true reachAssessed = true distanceYards = 1 approved = true evidence = 'An adjacent foe in reach';
turnWound: RpgExpandedWound id = 'recorded-club-hit' profile = turnTargetProfile amount = 2;
turnManeuver: RpgExpandedFrenzyManeuver kind = 'all-out-attack' option = 'strong' target = turnTarget turn = frenzyTurn;
frenzyTurn: RpgExpandedFrenzyTurn id = 'first-turn' episode = frenzyEpisode battle = turnBattle fighter = turnFighter
    choice = turnChoice maneuver = turnManeuver wounds = [turnWound] approved = true
    evidence = 'Recorded legal strong all-out attack: ordinary hit, failed defense, two final injury after protection';
frenzyExitHealth: RpgExpandedFrenzyExitHealth owner = frenzyExit;
frenzyExit: RpgExpandedFrenzyExit id = 'downed-exit' episode = frenzyEpisode profile = fearProfile trait = frenzyTrait
    trigger = turnTarget occasion = 'downed-foe' downed = turnTarget health = frenzyExitHealth stressRelation = 'unrelated'
    disabledEvidence = 'The struck foe surrenders and ceases resistance' evidence = 'A new exit opportunity after downing the foe';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1370)
        {
            fearProfile.equipment = [turnWeapon]; turnBattle.active = true;
            turnBattle.order = [turnTarget,turnFighter]; turnBattle.index = 2; return nil;
        }
        if (code == 1371 || code == 1372) { frenzyTurn.apply(); if (code == 1372) throw new RpgError(); return nil; }
        if (code == 1373) { frenzyTurn.assess(); return nil; }
        if (code == 1374)
        {
            event('test.frenzy-turn'); eventValue(turnTargetProfile.injury); eventValue(frenzyEpisode.turns.length());
            eventValue(frenzyEpisode.state); eventValue(fearProfile.effectiveShock()); eventValue(rpgRandom.draws);
            eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1375 || code == 1376) { frenzyExit.resolve(); if (code == 1376) throw new RpgError(); return nil; }
        if (code == 1377) { turnWound.amount = 3; frenzyTurn.assess(); return nil; }
        if (code == 1378) { turnBattle.step(turnFighter,turnManeuver); return nil; }
        return inherited(context);
    }
;
