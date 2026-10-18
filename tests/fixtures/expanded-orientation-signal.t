#include "expanded-orientation-route.t"
orientationGoodSignal: RpgExpandedOrientationSignalReport id = 'working-network' profile = bleedProfile frame = 'harbor'
    network = 'local-navigation' available = true compatible = true approved = true evidence = 'Current compatible unjammed network coverage';
orientationJammedSignal: RpgExpandedOrientationSignalReport id = 'jammed-network' profile = bleedProfile frame = 'harbor'
    network = 'local-navigation' available = true compatible = true jammed = true approved = true evidence = 'Current local jamming';
orientationWrongSignal: RpgExpandedOrientationSignalReport id = 'incompatible-network' profile = bleedProfile frame = 'harbor'
    network = 'foreign-navigation' available = true compatible = nil approved = true evidence = 'Current signal format is incompatible';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 9600)
        {
            bleedProfile.traits = [orientationTrait]; orientationTrait.level = 2; orientationTrait.signalDependent = true;
            bleedProfile.orientationEnvironment = 'local'; bleedProfile.orientationFrame = 'harbor'; return nil;
        }
        if (code == 9601 || code == 9607)
        { orientationGoodSignal.record(); if (code == 9607) throw new RpgError(); return nil; }
        if (code == 9602) { orientationJammedSignal.record(); return nil; }
        if (code == 9603) { orientationWrongSignal.record(); return nil; }
        if (code == 9604)
        {
            event('test.orientation-signal'); eventValue(orientationTrait.creationCost()); eventValue(bleedProfile.skillScore(fallSkill));
            eventValue(bleedProfile.effectiveOrientationSenseLevel()); eventValue(bleedProfile.orientationSignalReports.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9605)
        {
            event('test.orientation-signal-error');
            try { bleedProfile.skillScore(fallSkill); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(bleedProfile.orientationSignalReports.length()); return nil;
        }
        if (code == 9606)
        {
            local copy = rpgExpandedTemplateTraits.copy(orientationTrait);
            event('test.orientation-signal-copy'); eventValue(copy != orientationTrait ? 1 : 0);
            eventValue(copy.creationCost()); eventValue(copy.signalDependent ? 1 : 0); return nil;
        }
        if (code == 9608)
        {
            local report = new RpgExpandedOrientationSignalReport(); report.id = 'renewed-observation'; report.profile = bleedProfile;
            report.frame = 'harbor'; report.network = 'local-navigation'; report.available = true; report.compatible = true;
            report.approved = true; report.evidence = 'Current observation after elapsed time'; report.record(); return nil;
        }
        if (code == 9610) { orientationTrait.level = 1; return nil; }
        if (code == 9611) { bleedProfile.orientationFrame = 'mountains'; return nil; }
        if (code == 9609) { orientationGoodSignal.assess(); return nil; }
        return inherited(context);
    }
;
