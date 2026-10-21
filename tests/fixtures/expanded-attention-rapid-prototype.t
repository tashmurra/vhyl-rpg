#include "expanded-attention-prototype.t"
attentionRapidCapability: RpgExpandedInventor approved = true tier = 'rapid';
attentionRapidPermission: RpgExpandedInventionPermission inventor = fearProfile mode = 'rapid' designApproved = true evidence = 'Approved optical design';
attentionRapidDesign: RpgExpandedRapidProposal inventor = fearProfile skill = attentionBuildSkill permission = attentionRapidPermission
    description = 'Rapid survey instrument' mechanism = 'Optical measurement' evidence = 'Feasible rapid design'
    approved = true techLevel = 8 category = 'simple' retailPrice = 1000;
attentionComponents: RpgLiteItem id = 'optical-components' cost = 10 weight = 100;
attentionComponentPurchase: RpgExpandedRapidPurchase id = 'components' project = attentionBuildProject payer = fearProfile item = attentionComponents
    approved = true available = true permitted = true evidence = 'Purchased component bundle and facility';
attentionRapidBuild: RpgExpandedRapidPrototypeStart id = 'rapid-survey' project = attentionBuildProject payer = fearProfile components = attentionComponentPurchase
    approved = true evidence = 'A rapid attempt with reserved components';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 1300)
        {
            fearProfile.traits = [attentionTrait,attentionRapidCapability]; fearProfile.skills = [attentionBuildTraining];
            fearProfile.money = 100000; fearProfile.techLevel = 8; fearProfile.campaignTL = 8;
            fearRules.cinematicInvention = true; fearRules.rapidInvention = true;
            attentionBuildProject.proposal = attentionRapidDesign; attentionBlueprint.apply();
            attentionComponentPurchase.acquire(); attentionRapidBuild.begin();
            attentionBuildWork.attempt = attentionRapidBuild; attentionBuildWork.apply();
            attentionWork.subject = attentionRapidBuild; attentionWork.begin();
            attentionWorkSecond.seconds = 0; attentionWorkSecond.money = 0;
            attentionBuildFailure.attempt = attentionRapidBuild; attentionBuildLater.attempt = attentionRapidBuild; return nil;
        }
        if (code == 1301)
        {
            event('test.attention-rapid'); eventValue(fearProfile.money); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(holds(fearProfile.equipment,attentionComponents) ? 1 : 0);
            eventValue(attentionComponents.rapidPrototypeReservation == attentionRapidBuild ? 1 : 0);
            eventValue(attentionComponents.rapidComponentSpent);
            eventValue(attentionBuildProject.activePrototype == attentionRapidBuild ? 1 : 0); return nil;
        }
        if (code == 1302)
        { event('test.attention-rapid-work'); eventValue(attentionBuildLater.apply().reason); return nil; }
        return inherited(context);
    }
;
