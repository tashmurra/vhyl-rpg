#include "expanded-rage-injury-window.t"
#include <vhyl-rpg-expanded-traits.t>
frenzyTrait: RpgExpandedFrenzy approved = true;
frenzyEpisode: RpgExpandedFrenzyEpisode id = 'injury-response' profile = fearProfile trait = frenzyTrait
    entry = frenzyEntry approved = true evidence = 'The recorded injury triggers an owned episode';
frenzyEntry: RpgExpandedFrenzyInjuryTrigger id = 'injury-entry' profile = fearProfile trait = frenzyTrait
    trigger = rageReceipt injuryReceipt = rageReceipt episode = frenzyEpisode
    evidence = 'The character suffered these wounds this second' stressRelation = 'unrelated';
frenzyInput: object rollValue = 13;
modify rpgRandom roll() { self.draws += 3; return frenzyInput.rollValue; };
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1310) { fearProfile.traits = [frenzyTrait]; rageFirst.apply(); rageSecond.apply(); rageReceipt.record(); return nil; }
        if (code == 1311 || code == 1312)
        { frenzyEntry.resolve(); if (code == 1312) throw new RpgError(); return nil; }
        if (code == 1313) { frenzyEntry.assess(); return nil; }
        if (code == 1314)
        {
            event('test.frenzy-entry'); eventValue(frenzyEpisode.state);
            eventValue(fearProfile.frenzyEpisodes.length()); eventValue(fearProfile.injury);
            eventValue(fearProfile.shock); eventValue(fearProfile.effectiveShock());
            eventValue(fearProfile.healthBlocksDefense() ? 1 : 0);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1315) { frenzyInput.rollValue = 3; return nil; }
        if (code == 1316) { frenzyEpisode.enter(frenzyEntry); return nil; }
        if (code == 1317) { frenzyEpisode.state = 'new'; fearProfile.frenzyActive(); return nil; }
        if (code == 1318) { frenzyTrait.mitigated = true; return nil; }
        if (code == 1319) { frenzyEntry.witnessed = true; frenzyEntry.assess(); return nil; }
        if (code == 1320)
        {
            fearProfile.injury = 8; fearProfile.shock = 4; fearProfile.stunned = true;
            event('test.frenzy-effects'); eventValue(fearProfile.move());
            eventValue(fearProfile.combatStunned() ? 1 : 0); eventValue(fearProfile.physicalStunned() ? 1 : 0);
            eventValue(fearProfile.stunned ? 1 : 0); eventValue(fearProfile.effectiveShock());
            local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'death';
            eventValue(rpgLiteScore(fearProfile,context)); eventValue(fearProfile.survivalAppearanceThreshold()); return nil;
        }
        return inherited(context);
    }
;
