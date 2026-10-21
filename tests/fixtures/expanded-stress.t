#include "expanded-fear-event-traits.t"
#include <vhyl-rpg-expanded-stress.t>
stressPolicy: RpgExpandedStressPolicy;
stressState: RpgExpandedStressState profile = fearProfile policy = stressPolicy;
stressInput: object resolution = nil rest = nil;
stressContext: RpgLiteContext attribute = rpgIQ kind = 'skill';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1400) { stressState.configure(); return nil; }
        if (code == 1401 || code == 1402)
        {
            local gain = new RpgExpandedStressGain(); gain.id = 'gain-' + toString(fearInput.row); gain.cause = 'cause-' + toString(fearInput.row);
            gain.state = stressState; gain.severity = 'severe'; gain.evidence = 'A distinct authored disturbing event';
            gain.apply(); if (code == 1402) throw new RpgError(); return nil;
        }
        if (code == 1403 || code == 1404)
        {
            if (stressInput.resolution == nil || stressInput.resolution.result != nil)
            {
                local resolution = new RpgExpandedStressResolution(); resolution.decision = stressState.pending();
                resolution.choice = fearInput.row == 1 ? 'strain' : fearInput.row == 2 ? 'fear' : 'coping';
                resolution.evidence = 'The author records the selected threshold response';
                if (resolution.choice == 'fear') resolution.fearEvent = ownedFearEvent;
                stressInput.resolution = resolution;
            }
            stressInput.resolution.apply(); if (code == 1404) throw new RpgError(); return nil;
        }
        if (code == 1405)
        {
            event('test.stress'); eventValue(stressState.balance); eventValue(stressState.episode); eventValue(stressState.gains.length());
            eventValue(stressState.decisions.length()); eventValue(stressState.pending() == nil ? 0 : stressState.pending().threshold);
            eventValue(stressState.strains.length()); eventValue(stressState.strainPenalty()); eventValue(rpgLedger.seconds);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 1406) { stressPolicy.cap = 13; stressState.validate(); return nil; }
        if (code == 1407) { local result = rpgLiteCheck(fearProfile,stressContext); event('test.stress-check'); eventValue(result.status); eventValue(result.reason); return nil; }
        if (code == 1408) { stressInput.resolution.completeFear(fearEpisode); return nil; }
        if (code == 1409) { rpgSpendTime(fearInput.row); return nil; }
        if (code == 1410)
        {
            local rest = new RpgExpandedStressRecovery(); rest.id = 'rest-' + toString(fearInput.row); rest.state = stressState;
            rest.safe = true; rest.evidence = 'A quiet guarded hour with no interruption'; rest.begin(); stressInput.rest = rest; return nil;
        }
        if (code == 1411) { stressInput.rest.interrupt(); return nil; }
        if (code == 1412) { stressInput.rest.complete(); return nil; }
        if (code == 1413) { stressPolicy.gains = [12,12,12]; return nil; }
        if (code == 1414) { stressState.decisions[1].threshold = 1; stressState.validate(); return nil; }
        if (code == 1415) { stressInput.resolution.finish(); return nil; }
        if (code == 1416) { local result = rpgLiteWound(fearProfile,1); return nil; }
        if (code == 1417)
        {
            event('test.stress-score'); eventValue(rpgLiteScore(fearProfile,stressContext));
            eventValue(fearProfile.healthSelfControlModifier(eventQuirk)); eventValue(fearProfile.injury);
            local defense = new RpgLiteContext(); defense.kind = 'defense'; defense.attribute = rpgDX;
            eventValue(fearProfile.healthAttributeModifier(defense)); return nil;
        }
        if (code == 1419)
        {
            event('test.stress-passive');
            foreach (local kind in ['defense','death','consciousness','temperature','resistance','first-aid'])
            { local passive = new RpgLiteContext(); passive.attribute = rpgHT; passive.kind = kind;
              eventValue(fearProfile.healthCheckReason(passive) == nil ? 1 : 0); }
            return nil;
        }
        if (code == 1418)
        { local gain = stressState.gains[stressState.gains.length()]; event('test.stress-gain');
          eventValue(gain.requested); eventValue(gain.applied); eventValue(gain.discarded); return nil; }
        return inherited(context);
    }
;
