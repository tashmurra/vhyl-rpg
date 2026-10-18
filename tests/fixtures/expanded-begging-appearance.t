#include "expanded-appearance.t"
modify beggingContext invertAppearance = true appearanceContext = appearanceReaction;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 24800 || code == 24801)
        {
            if (code == 24801) beggingContext.appearanceContext = nil;
            event('test.begging-appearance');
            try { eventValue(rpgLiteScore(crossPhysician,beggingContext)); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            return nil;
        }
        if (code == 24802)
        {
            appearanceReaction.attracted = !appearanceReaction.attracted;
            try { beggingHour.assess(); }
            catch (RpgExpandedError error) { event('test.begging-appearance-binding'); eventValue(error.reason); }
            return nil;
        }
        return inherited(context);
    }
;
