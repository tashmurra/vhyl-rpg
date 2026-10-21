#include "expanded-attention-work.t"
#include <vhyl-rpg-expanded-equipment.t>
#include <vhyl-rpg-expanded-technology.t>
attentionBuildSkill: RpgLiteSkill id = 'engineer' attribute = rpgIQ difficulty = 2;
attentionBuildTraining: RpgTraining skill = attentionBuildSkill points = 24;
attentionBuildProposal: RpgExpandedInventionProposal inventor = fearProfile skill = attentionBuildSkill approved = true
    description = 'Survey instrument' mechanism = 'Optical measurement' evidence = 'Feasible optical design'
    techLevel = 8 category = 'simple' retailPrice = 1000;
attentionBuildProject: RpgExpandedInventionProject proposal = attentionBuildProposal;
attentionBlueprint: RpgExpandedInventionBlueprint project = attentionBuildProject reference = 'survey-drawings'
    acquired = true actualDesign = true approved = true evidence = 'Complete acquired construction drawings';
attentionWorkshop: RpgExpandedInventionFacilities project = attentionBuildProject payer = fearProfile approved = true evidence = 'Fund the workshop';
attentionBuild: RpgExpandedPrototypeStart id = 'survey-prototype' project = attentionBuildProject payer = fearProfile
    approved = true evidence = 'A funded attempt';
attentionBuildWork: RpgExpandedPrototypeWork id = 'prior-work' attempt = attentionBuild seconds = 60
    approved = true uninterrupted = true evidence = 'Earlier committed work';
attentionBuildLater: RpgExpandedPrototypeWork id = 'later-work' attempt = attentionBuild seconds = 60
    approved = true uninterrupted = true evidence = 'Must reject after task failure';
attentionBuildCompletion: RpgExpandedPrototypeCompletion attempt = attentionBuild;
attentionBuildFailure: RpgExpandedAttentionPrototypeFailure attempt = attentionBuild work = attentionWork approved = true
    evidence = 'The failed attention task was this prototype attempt';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1280)
        {
            fearProfile.traits = [attentionTrait]; fearProfile.skills = [attentionBuildTraining]; fearProfile.money = 100000;
            fearProfile.techLevel = 8; fearProfile.campaignTL = 8;
            attentionBlueprint.apply(); attentionWorkshop.fund(); attentionBuild.begin(); attentionBuildWork.apply();
            attentionWork.subject = attentionBuild; attentionWork.begin();
            attentionWorkSecond.seconds = 0; attentionWorkSecond.money = 0; return nil;
        }
        if (code == 1281 || code == 1282)
        { attentionBuildFailure.apply(); if (code == 1282) throw new RpgError(); return nil; }
        if (code == 1283)
        {
            event('test.attention-prototype'); eventValue(attentionBuildProject.activePrototype == attentionBuild ? 1 : 0);
            eventValue(attentionBuild.attentionFailure == nil ? 0 : 1); eventValue(attentionBuild.workedSeconds);
            eventValue(fearProfile.money); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(attentionBuildFailure.retainedMoney); eventValue(attentionBuildFailure.retainedWork); return nil;
        }
        if (code == 1284)
        {
            event('test.attention-prototype-gates'); eventValue(attentionBuildLater.apply().reason);
            eventValue(attentionBuildCompletion.apply().reason); return nil;
        }
        return inherited(context);
    }
;
