#include "expanded-drowning-interruption.t"
secondSwimmer: RpgExpandedProfile rules = swimRules;
secondSwim: RpgExpandedSwimmingEncounter id = 'second-river' profile = secondSwimmer
    defaultAvailable = true evidence = 'Second swimmer in deep water';
secondSubmersion: RpgExpandedDrowningExposure id = 'second-submersion' profile = secondSwimmer swimming = secondSwim
    approved = true evidence = 'Second swimmer becomes unconscious and fully submerged';
secondPatientCare: RpgExpandedDrowningResuscitation id = 'second-patient' exposure = secondSubmersion healer = drowningHealer
    skill = drowningAidSkill modernTechnique = true approved = true evidence = 'Both patients accessible to the same rescuer';
modify SwimFixtureAction
    exec(context)
    {
        local code = swimInput.code;
        if (code == 17600)
        {
            secondSwim.start(); secondSwimmer.unconscious = true; secondSubmersion.start(); return nil;
        }
        if (code == 17601)
        {
            local value = secondPatientCare.start();
            event('test.care-owner-result'); eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 17602)
        {
            event('test.care-owner'); eventValue(secondPatientCare.startedAt != nil);
            eventValue(secondSubmersion.resuscitations.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code >= 17603 && code <= 17605)
        {
            if (code == 17603) drowningCare.cancelledAt = nil;
            if (code == 17604) drowningCare.completedAt = rpgLedger.seconds;
            if (code == 17605) swimSubmersion.resuscitations = [];
            try { swimPatient.validateFeatures(); }
            catch (RpgExpandedError error) { event('test.care-owner-history'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
