#include "expanded-sustenance.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-hazards.t>
sustenanceEpisode: RpgExpandedSustenanceDeprivation id = 'missed-bath' profile = bleedProfile requirement = sustenanceTrait
    approved = true evidence = 'The required daily contact deadline has just passed without sufficient contact';
sustenanceTick: RpgExpandedSustenanceInjury id = 'first' episode = sustenanceEpisode;
sustenanceSecond: RpgExpandedSustenanceInjury id = 'second' episode = sustenanceEpisode;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 11700) { bleedProfile.traits = [sustenanceTrait]; sustenanceEpisode.begin(); return nil; }
        if (code == 11701) { rpgSpendTime(3600); return nil; }
        if (code == 11702)
        {
            local value = sustenanceTick.assess(); event('test.sustenance-injury-preview');
            eventValue(value.status); eventValue(value.reason); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 11703 || code == 11704)
        { sustenanceTick.apply(); if (code == 11704) throw new RpgError(); return nil; }
        if (code == 11705)
        {
            event('test.sustenance-injury-state'); eventValue(bleedProfile.injury); eventValue(sustenanceEpisode.ticks.length());
            eventValue(bleedProfile.expandedWounds.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 11706)
        {
            event('test.sustenance-boundary');
            try { rpgLedger.validateAdvance(1); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        if (code == 11707) { sustenanceSecond.apply(); return nil; }
        return inherited(context);
    }
;
