#include "expanded-intrusive-replay.t"
replaySenseContext: RpgLiteContext attribute = rpgPerception kind = 'vision';
replayMemoryContext: RpgLiteContext attribute = rpgIQ externalInput = 'none';
replayExternalContext: RpgLiteContext attribute = rpgIQ externalInput = 'required';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1060)
        {
            event('test.replay-senses');
            foreach (local c in [replaySenseContext,replayExternalContext])
            { local result = rpgLiteCheck(fearProfile,c); eventValue(result.reason); }
            eventValue(fearProfile.externalInputReason()); eventValue(fearProfile.fearAuraPerceptionReason(nil));
            eventValue(fearProfile.healthCheckReason(replayMemoryContext)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1061) { replaySenseContext.externalInput = 'none'; return nil; }
        if (code == 1062)
        { event('test.replay-external-fear'); eventValue(ownedFearEvent.assess().reason); eventValue(rpgRandom.draws); return nil; }
        if (code == 1063) { replayMemoryContext.skill = replaySkill; return nil; }
        return inherited(context);
    }
;
