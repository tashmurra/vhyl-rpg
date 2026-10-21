#include "expanded-fear-panic.t"
cryGate: RpgExpandedActionGate id = 'crying-health' profile = bleedProfile purpose = 'do-nothing'
    evidence = 'Stationary crying during the authored panic episode';
cryActivity: RpgExpandedFearPanicCrying id = 'crying-interval' episode = panicEpisode seconds = 60 healthGate = cryGate;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10700)
        {
            event('test.crying-preview'); local value = cryActivity.assess(); eventValue(value.status); eventValue(value.reason);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10701 || code == 10702)
        {
            local value = cryActivity.apply(); event('test.crying-result'); eventValue(value.status); eventValue(value.seconds);
            if (code == 10702) throw new RpgError(); return nil;
        }
        if (code == 10703)
        {
            event('test.crying-state'); eventValue(panicEpisode.activities.length()); eventValue(bleedProfile.effortHistory.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10704)
        {
            event('test.panic-gates'); eventValue(bleedProfile.healthEffortReason('action',nil,nil,true));
            eventValue(bleedProfile.healthEffortReason('do-nothing',nil,nil,nil));
            eventValue(bleedProfile.healthManeuverReason('attack')); eventValue(bleedProfile.healthManeuverReason('nothing')); return nil;
        }
        if (code == 10705) { cryActivity.seconds = 61; return nil; }
        return inherited(context);
    }
;

movePanicRoom: Room 'Open Gallery';
modify player rpgProfile = bleedProfile;
movePanicGate: RpgExpandedPanicMovementGate id = 'panic-motion-health' profile = bleedProfile
    activity = movePanicActivity evidence = 'Agitated movement along the recorded route';
movePanicActivity: RpgExpandedFearPanicMovement id = 'panic-motion' episode = panicEpisode seconds = 1
    healthGate = movePanicGate actor = player origin = bleedRoom destination = movePanicRoom distanceYards = 3
    approved = true routeEvidence = 'An open level three-yard passage with no intervening hazards or reactions';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10710) { panicEpisode.behaviorKind = 'agitated-motion'; return nil; }
        if (code == 10711 || code == 10712 || code == 10713)
        {
            local value = code == 10711 ? movePanicActivity.assess() : movePanicActivity.apply();
            event('test.panic-movement'); eventValue(value.status); eventValue(value.reason);
            if (code == 10713) throw new RpgError(); return nil;
        }
        if (code == 10714)
        {
            event('test.panic-movement-state'); eventValue(location.get(player) == movePanicRoom ? 1 : 0);
            eventValue(panicEpisode.activities.length()); eventValue(bleedProfile.effortHistory.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10715) { movePanicActivity.distanceYards = 6; return nil; }
        if (code == 10716) { movePanicActivity.routeEvidence = nil; return nil; }
        if (code == 10717) { bleedProfile.injury = 10; bleedInput.forcedRoll = 18; movePanicActivity.distanceYards = 1; return nil; }
        if (code == 10718) { movePanicGate.apply(); return nil; }
        return inherited(context);
    }
;

expressionGate: RpgExpandedPanicExpressionGate id = 'panic-expression-health' profile = bleedProfile
    activity = expressionActivity purpose = 'action' requiresSpeech = true evidence = 'Incoherent vocalization during panic';
expressionActivity: RpgExpandedFearPanicExpression id = 'panic-expression' episode = panicEpisode seconds = 60
    healthGate = expressionGate mode = 'vocalization' approved = true
    portrayal = 'Repeats a meaningless syllable without addressing anyone'
    evidence = 'Stationary noncommunicative expression, no contact with objects and no purposeful progress';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10720) { panicEpisode.behaviorKind = 'other-pointless'; return nil; }
        if (code == 10721 || code == 10722 || code == 10723)
        {
            local value = code == 10721 ? expressionActivity.assess() : expressionActivity.apply();
            event('test.panic-expression'); eventValue(value.status); eventValue(value.reason);
            if (code == 10723) throw new RpgError(); return nil;
        }
        if (code == 10724) { expressionActivity.portrayal = nil; return nil; }
        if (code == 10725) { expressionActivity.seconds = 61; return nil; }
        if (code == 10726) { expressionGate.apply(); return nil; }
        if (code == 10727) { expressionGate.requiresSpeech = nil; return nil; }
        return inherited(context);
    }
;
