#include "expanded-shadowing-assessment.t"
modify shadowingContextFixture modifier = 5;
shadowRoundOccurrence: object;
shadowFollowerCost: RpgExpandedMarchHourCost id = 'shadow-follower-hour' profile = crossPhysician interval = shadowRoundOccurrence
    approved = true evidence = 'Continuous foot pursuit' dropDestination = healthRoom;
shadowTargetCost: RpgExpandedMarchHourCost id = 'shadow-target-hour' profile = beggingObserver interval = shadowRoundOccurrence
    approved = true evidence = 'Continuous target travel' dropDestination = healthRoom;
shadowFollowerProgress: RpgExpandedMarchProgress cost = shadowFollowerCost;
shadowTargetProgress: RpgExpandedMarchProgress cost = shadowTargetCost;
shadowFollowerFirst: RpgExpandedMarchStep id = 'follower-first' progress = shadowFollowerProgress seconds = 600;
shadowTargetFirst: RpgExpandedMarchStep id = 'target-first' progress = shadowTargetProgress seconds = 600;
shadowFollowerSecond: RpgExpandedMarchStep id = 'follower-second' progress = shadowFollowerProgress seconds = 600;
shadowTargetSecond: RpgExpandedMarchStep id = 'target-second' progress = shadowTargetProgress seconds = 600;
shadowFirstMovement: RpgExpandedMarchStepGroup id = 'shadow-first-movement' steps = [shadowFollowerFirst,shadowTargetFirst];
shadowSecondMovement: RpgExpandedMarchStepGroup id = 'shadow-second-movement' steps = [shadowFollowerSecond,shadowTargetSecond];
shadowFirstRound: RpgExpandedShadowingRound id = 'shadow-first' follower = crossPhysician target = beggingObserver
    followerContext = shadowingContextFixture targetContext = visionContextFixture occurrence = shadowRoundOccurrence
    movement = shadowFirstMovement approved = true evidence = 'Both participants walk through the crowd';
shadowSecondRound: RpgExpandedShadowingRound id = 'shadow-second' follower = crossPhysician target = beggingObserver
    followerContext = shadowingContextFixture targetContext = visionContextFixture occurrence = shadowRoundOccurrence
    previous = shadowFirstRound movement = shadowSecondMovement approved = true evidence = 'Continuous pursuit through the same crowd';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 29600 || code == 29601)
        { shadowFirstRound.resolve(); if (code == 29601) throw new RpgError(); return nil; }
        if (code == 29602 || code == 29603)
        { shadowSecondRound.resolve(); if (code == 29603) throw new RpgError(); return nil; }
        if (code == 29604)
        {
            event('test.shadow-round'); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(crossPhysician.shadowingRounds.length()); eventValue(beggingObserver.shadowingRounds.length());
            eventValue(shadowFollowerProgress.elapsed); eventValue(shadowTargetProgress.elapsed);
            eventValue(crossPhysician.fatigue); eventValue(beggingObserver.fatigue); return nil;
        }
        if (code == 29605 || code == 29606)
        { local value = code == 29605 ? shadowFirstRound.assess() : shadowSecondRound.assess();
          event('test.shadow-round-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 29607)
        {
            shadowFirstRound.initiallyAware = true; shadowFirstRound.targetContext = shadowTargetContext;
            shadowSecondRound.targetContext = shadowTargetContext;
            shadowFollowerFirst.seconds = 300; shadowTargetFirst.seconds = 300;
            shadowFollowerSecond.seconds = 300; shadowTargetSecond.seconds = 300; return nil;
        }
        if (code == 29608) { shadowingContextFixture.modifier = -4; return nil; }
        if (code == 29609)
        { local o = shadowFirstRound.result.outcome; event('test.shadow-round-outcome');
          eventValue(o == nil ? 0 : 1);
          if (o != nil) { eventValue(o.lost ? 1 : 0); eventValue(o.seen ? 1 : 0); eventValue(o.wrongTarget ? 1 : 0);
              eventValue(o.targetAware ? 1 : 0); eventValue(o.targetBelievesEscape ? 1 : 0); }
          return nil; }
        if (code == 29610) { shadowFirstRound.result.outcome.lost = true; shadowFirstRound.assess(); return nil; }
        if (code == 29611) { shadowFirstMovement.apply(); shadowFollowerFirst.apply(); shadowTargetFirst.apply(); return nil; }
        if (code == 29612) { shadowTargetFirst.seconds = 599; shadowFirstRound.assess(); return nil; }
        return inherited(context);
    }
;
