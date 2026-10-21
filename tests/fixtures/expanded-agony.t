#include "expanded-paralysis.t"
agonyEpisode: RpgExpandedAgony id = 'pain-episode' profile = bleedProfile durationSeconds = 61
    approved = true evidence = 'A resolved original effect causes sixty-one seconds of agony';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 490) { agonyEpisode.assess(); return nil; }
        if (code == 491 || code == 492)
        { agonyEpisode.apply(); if (code == 492) throw new RpgError(); return nil; }
        if (code == 493 || code == 494)
        { agonyEpisode.pay('second'); if (code == 494) throw new RpgError(); return nil; }
        if (code == 495)
        {
            local check = new RpgLiteContext(); check.attribute = rpgDX;
            event('test.agony'); eventValue(bleedProfile.agonized() ? 1 : 0); eventValue(bleedProfile.posture);
            eventValue(bleedProfile.fatigue); eventValue(rpgLiteScore(bleedProfile,check));
            eventValue(bleedProfile.healthDefensePenalty()); eventValue(bleedProfile.effortHistory.length());
            eventValue(agonyEpisode.payments.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 496) { local trait = new RpgLiteTrait(); trait.id = 'low-pain-threshold'; bleedProfile.traits = [trait]; return nil; }
        if (code == 497) { bleedProfile.traits = [rpgLiteMakeTrait('high-pain-threshold',1,nil)]; return nil; }
        if (code == 498)
        {
            event('test.agony-recurrence');
            eventValue(agonyEpisode.recurrenceBonus('interrogation',true,'The questioner can repeat the original effect'));
            eventValue(agonyEpisode.recurrenceBonus('intimidation',true,'The threat is credible'));
            eventValue(agonyEpisode.recurrenceBonus('diplomacy',true,'Unrelated negotiation'));
            eventValue(agonyEpisode.recurrenceBonus('intimidation',nil,nil)); return nil;
        }
        if (code == 499) { agonyEpisode.durationSeconds = 60; return nil; }
        if (code == 500)
        {
            local check = new RpgLiteContext(); check.attribute = rpgWill; check.kind = 'pain-cry';
            event('test.agony-pain-cry'); eventValue(rpgLiteScore(bleedProfile,check)); return nil;
        }
        return inherited(context);
    }
;
