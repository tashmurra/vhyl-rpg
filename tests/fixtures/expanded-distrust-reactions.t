#include "expanded-observed-reactions.t"
distrustTrait: RpgExpandedPervasiveDistrust approved = true;
subjectDistrustTrait: RpgExpandedPervasiveDistrust approved = true;
subjectDistrustFact: RpgExpandedDistrustObservation id = 'subject-distrust' subject = bleedProfile observer = distrustAudience
    typicalObserver = true approved = true evidence = 'The author confirms the ordinary adverse response to the subject distrust';
distrustAudience: RpgExpandedProfile traits = [distrustTrait];
distrustContext: RpgExpandedDistrustReactionContext subject = bleedProfile observer = distrustAudience
    observations = [humorObservation] observerIsNpc = true stranger = true approved = true
    evidence = 'Author confirms a nonplayer observer meeting an unfamiliar subject'
    adjustments = [['helpful',4,'The subject provided useful assistance'],['hostile-group',-2,'The observer recognizes an unfriendly affiliation']];
distrustAttempt: RpgExpandedObservedReactionAttempt encounter = observedEncounter approach = 'distrust-greeting' socialContext = distrustContext;
distrustBaseline: RpgLiteProfile;
distrustBaselineContext: RpgLiteSocialContext modifier = 2;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 9900)
        {
            humorObservation.observer = distrustAudience; callousObservation.observer = distrustAudience;
            observedEncounter.audience = distrustAudience; return nil;
        }
        if (code == 9901)
        {
            event('test.distrust-modifier'); eventValue(distrustTrait.creationCost());
            eventValue(rpgLiteReactionModifier(bleedProfile,distrustContext)); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9902 || code == 9903)
        {
            local value = distrustAttempt.resolve(); event('test.distrust-result'); eventValue(value.status); eventValue(value.total);
            eventValue(rpgRandom.draws); if (code == 9903) throw new RpgError(); return nil;
        }
        if (code == 9904) { distrustContext.stranger = nil; return nil; }
        if (code == 9905) { distrustContext.observerIsNpc = nil; return nil; }
        if (code == 9906) { distrustContext.modifier = 1; return nil; }
        if (code == 9907)
        {
            event('test.distrust-error');
            try { distrustAttempt.resolve(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 9910)
        {
            bleedProfile.traits = bleedProfile.traits + [subjectDistrustTrait]; subjectDistrustFact.record();
            distrustContext.observations = [humorObservation,subjectDistrustFact]; return nil;
        }
        if (code == 9908)
        {
            event('test.distrust-baseline'); eventValue(rpgLiteReactionModifier(distrustBaseline,distrustBaselineContext));
            eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
