#include "expanded-extreme-panic.t"
panicExit: Room 'Lower Gallery';
panicFlightParalysis: RpgExpandedParalysis id = 'flight-paralysis' profile = fearProfile durationSeconds = 60
    positionAssessed = true balanced = true approved = true
    evidence = 'Conscious and balanced but unable to initiate voluntary movement';
modify player rpgProfile = fearProfile;
modify extremeFirst kind = 'flight' actor = player origin = fearRoom destination = panicExit distanceYards = 3
    routeEvidence = 'Three unobstructed yards through an open arch; no intervening hazard or reaction';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 570)
        { local v = extremeFirst.assess(); event('test.panic-flight-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 571)
        { event('test.panic-flight'); eventValue(location.get(player) == panicExit ? 1 : 0);
          eventValue(extremeEpisode.reactions.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 572) { extremeFirst.distanceYards = 6; return nil; }
        if (code == 573) { extremeFirst.routeEvidence = nil; return nil; }
        if (code == 574) { panicFlightParalysis.apply(); return nil; }
        if (code == 575)
        { event('test.panic-flight-paralysis'); eventValue(fearProfile.paralyzed() ? 1 : 0);
          eventValue(fearProfile.unconscious ? 1 : 0); eventValue(fearProfile.posture); return nil; }
        return inherited(context);
    }
;
