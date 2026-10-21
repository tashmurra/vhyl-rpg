#include "expanded-overstimulation.t"
overWound: RpgExpandedWound id = 'reactive-injury' profile = overOtherProfile amount = 1;
overStrike: RpgExpandedAdjudicatedStrike id = 'reactive-attack' attacker = overActor defender = overOther
    weapon = overWeapon mode = overMode attackScore = 12 attackRoll = 10 basicDamage = 1
    defenseKind = 'dodge' defenseScore = 8 defenseRoll = 10 wound = overWound approved = true
    legalityEvidence = 'A stationary physical response against the foe who attacked during the episode'
    resolutionEvidence = 'The author records an ordinary hit, failed dodge and one final torso injury';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 750) { overCounter.resolution = 'recorded'; overCounter.strike = overStrike; overCounter.battle = overBattle; return nil; }
        if (code == 751)
        {
            event('test.overstimulation-strike'); eventValue(overOtherProfile.injury);
            eventValue(fearProfile.adjudicatedStrikes.length()); eventValue(fearProfile.effortHistory.length());
            eventValue(overBattle.index); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(overCounter.executingStrike ? 1 : 0); return nil;
        }
        if (code == 752) { overStrike.apply(overCounter); return nil; }
        if (code == 753) { overStrike.attackRoll = 4; return nil; }
        if (code == 754) { overCounter.resolution = nil; return nil; }
        if (code == 755) { overStrike.attackScore = 11; overStrike.validateReceipt(); return nil; }
        if (code == 756) { overCounter.strike = nil; return nil; }
        if (code == 757) { overStrike.defenseRoll = 7; overStrike.basicDamage = 0; overStrike.wound = nil; return nil; }
        if (code == 758) { overStrike.attackRoll = 13; overStrike.basicDamage = 0; overStrike.wound = nil;
            overStrike.defenseKind = nil; overStrike.defenseScore = nil; overStrike.defenseRoll = nil; return nil; }
        return inherited(context);
    }
;
