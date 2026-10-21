#include "expanded-fear-mental.t"
overTrait: RpgExpandedOverstimulation approved = true;
overTrigger: RpgExpandedOverstimulationTrigger id = 'crowded-hall' profile = fearProfile trait = overTrait
    trigger = fearRoom situation = 'commotion' approved = true evidence = 'Several simultaneous conversations prevent decisive action';
overPlanning: RpgLiteContext attribute = rpgIQ deliberatePlanning = true;
overMode: RpgLiteAttackMode skillId = 'brawling';
overWeapon: RpgLiteWeapon id = 'punch' modes = [overMode] ready = true;
overOtherWeapon: RpgLiteWeapon id = 'punch' modes = [overMode] ready = true;
overOtherProfile: RpgExpandedProfile rules = fearRules equipment = [overOtherWeapon];
overActor: RpgLiteFighter profile = fearProfile weapon = overWeapon;
overOther: RpgLiteFighter profile = overOtherProfile weapon = overOtherWeapon;
overThird: RpgLiteFighter profile = overOtherProfile;
overBattle: RpgLiteBattle fighters = [overOther,overActor];
overIncoming: RpgLiteManeuver kind = 'attack' target = overActor;
overGate: RpgExpandedOverstimulationCounterGate id = 'reactive-turn' profile = fearProfile requiresMovement = true
    maneuver = overCounter evidence = 'A physical counterattack on the ordinary turn';
overCounter: RpgExpandedOverstimulationCounterManeuver target = overOther healthGate = overGate resolution = 'abridged';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 720)
        {
            mentalAward.trait = overTrait; mentalAward.tableTotal = fearInput.row == 9 ? 35 : 23;
            overTrait.selfControlRating = fearInput.row; fearProfile.creationComplete = true;
            fearProfile.disadvantageLimit = 0; fearProfile.equipment = [overWeapon];
            fearEventInput.initialRoll = 13; fearEventInput.tableRoll = 13;
            overBattle.active = true; overBattle.order = [overOther,overActor]; return nil;
        }
        if (code == 721 || code == 722)
        { overTrigger.resolve(); if (code == 722) throw new RpgError(); return nil; }
        if (code == 723)
        {
            event('test.overstimulation'); eventValue(fearProfile.activeOverstimulation() == nil ? 0 : 1);
            eventValue(fearProfile.mentalStun ? 1 : 0); eventValue(fearProfile.healthDefensePenalty());
            eventValue(overTrigger.attacks.length()); eventValue(overBattle.index);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 724)
        {
            event('test.overstimulation-permission'); eventValue(fearProfile.healthCheckReason(overPlanning));
            eventValue(fearProfile.healthManeuverReason('attack')); eventValue(fearProfile.healthManeuverReason('nothing'));
            eventValue(fearProfile.healthEffortReason('action',nil,nil,true)); return nil;
        }
        if (code == 725)
        { local v = overTrigger.assess(); event('test.overstimulation-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 726)
        {
            local value = overBattle.step(overOther,overIncoming);
            event('test.overstimulation-incoming'); eventValue(value.status); eventValue(value.reason);
            if (overTrigger.attacks.length() != 0) overCounter.notice = overTrigger.attacks[1];
            return nil;
        }
        if (code == 727 || code == 728)
        { overBattle.step(overActor,overCounter); if (code == 728) throw new RpgError(); return nil; }
        if (code == 729) { overCounter.target = overThird; return nil; }
        if (code == 730) { fearProfile.becomeUnconscious(); return nil; }
        if (code == 731 || code == 732)
        { overTrigger.end('stimulus-ended','The room empties and the commotion stops'); if (code == 732) throw new RpgError(); return nil; }
        if (code == 733) { overTrigger.check.roll = 3; overTrigger.assess(); return nil; }
        if (code == 734) { overTrigger.modifier = -10; return nil; }
        if (code == 735) { fearEventInput.initialRoll = 3; return nil; }
        if (code == 737)
        { fearProfile.traits = fearProfile.traits + [mentalVoices]; overTrigger.stressRelation = 'stress-related';
          fearEventInput.tableRoll = 6; return nil; }
        if (code == 738)
        { event('test.overstimulation-voices'); eventValue(fearProfile.phantomVoiceOccurrences.length());
          eventValue(overTrigger.phantomVoiceOccurrence == nil ? 0 : overTrigger.phantomVoiceOccurrence.active() ? 1 : 0); return nil; }
        if (code == 739)
        { event('test.overstimulation-defense'); eventValue(rpgLiteDefenseScore(overActor,overOther,overIncoming,'dodge')); return nil; }
        if (code == 736)
        { event('test.overstimulation-counter'); eventValue(overCounter.available(overActor));
          eventValue(fearProfile.healthManeuverRequestReason(overCounter)); eventValue(overCounter.healthAvailable(overActor)); return nil; }
        return inherited(context);
    }
;
