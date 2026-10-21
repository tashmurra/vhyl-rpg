#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-traits.t>
#include <vhyl-rpg-expanded-health.t>
clottingRoom: Room 'Treatment Room';
modify gameMain initialRoom = clottingRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2379)
    {
        local care = ['untreated','first-aid','definitive'];
        local value = rpgExpandedAssessImpairedClotting(args[1],args[2] != 0,care[args[3]]);
        event('test.clotting'); eventValue(value.intervalSeconds); eventValue(value.injury);
        eventValue(value.ordinaryHealingAllowed ? 1 : 0); eventValue(value.requiresDefinitiveCare ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2380)
    {
        local trait = new RpgExpandedImpairedClotting(); trait.approved = true;
        local profile = new RpgExpandedProfile(); profile.rules = new RpgExpandedRules(); profile.rules.scaledInjuryShock = true;
        profile.traits = [trait]; profile.ht = args[1];
        event('test.clotting-profile'); eventValue(trait.creationCost());
        try { rpgExpandedValidate(profile); eventValue('ready'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 2381)
    {
        local trait = new RpgExpandedImpairedClotting(); trait.approved = true;
        local profile = new RpgExpandedProfile(); profile.rules = new RpgExpandedRules();
        profile.rules.scaledInjuryShock = true; profile.rules.bleeding = true; profile.traits = [trait];
        local wound = new RpgExpandedWound(); wound.id = 'cut'; wound.profile = profile; wound.amount = 2; wound.apply();
        local classified = new RpgExpandedBleedingWound(); classified.wound = wound; classified.damageKind = 'cutting';
        classified.bleeds = true; classified.approved = true; classified.evidence = 'A confirmed cut';
        local episode = new RpgExpandedBleedingEpisode(); episode.id = 'ordinary'; episode.classification = classified;
        local value = episode.apply(); event('test.clotting-dispatch'); eventValue(value.status); eventValue(value.reason);
        eventValue(profile.bleedingHistory.length()); eventValue(rpgRandom.draws); return nil;
    }
    return rpgDispatchAction(verb,args);
}
