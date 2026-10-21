#include "expanded-goal-fixation.t"
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-templates.t>
fixationPackage: RpgExpandedTemplate traitRows = [['goal-fixation',1,nil,nil,['long-term','Recover the lost survey',12]]];
fixationCopies: object first = nil second = nil;
fixationCopyFulfillment: RpgExpandedFixationFulfillment id = 'first-survey' previousGoal = 'Recover the lost survey'
    nextGoal = 'Map the uncharted valley' approved = true evidence = 'Only the first character completed the survey search';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 860)
        {
            fixationCopies.first = fixationPackage.create(fearRules); fixationCopies.second = fixationPackage.create(fearRules);
            fixationCopyFulfillment.profile = fixationCopies.first; fixationCopyFulfillment.trait = fixationCopies.first.traits[1]; return nil;
        }
        if (code == 861 || code == 864)
        { fixationCopyFulfillment.apply(); if (code == 864) throw new RpgError(); return nil; }
        if (code == 862)
        {
            local first = fixationCopies.first; local second = fixationCopies.second;
            event('test.fixation-template'); eventValue(first != second && first.traits[1] != second.traits[1] ? 1 : 0);
            eventValue(first.fixationGoal(first.traits[1])); eventValue(second.fixationGoal(second.traits[1]));
            eventValue(first.fixationFulfillments.length()); eventValue(second.fixationFulfillments.length());
            eventValue(first.traits[1].creationCost()); eventValue(second.traits[1].creationCost()); return nil;
        }
        if (code == 863)
        {
            local original = fixationCopies.first.traits[1]; local copy = rpgExpandedCopyTemplateTrait(original);
            event('test.fixation-copy'); eventValue(copy != original ? 1 : 0); eventValue(copy.initialGoal);
            eventValue(copy.selfControlNumber()); eventValue(copy.creationCost()); eventValue(copy.fearAcquisition); return nil;
        }
        if (code == 865 || code == 866)
        {
            event('test.fixation-template-invalid');
            try
            {
                if (code == 865) rpgExpandedTemplateTraits.rated('goal-fixation',1,nil,12);
                else rpgExpandedTemplateTraits.configured('goal-fixation',1,nil,['long-term','Recover the survey',8]);
                eventValue('accepted');
            }
            catch (RpgExpandedError error) { eventValue(error.reason); } return nil;
        }
        return inherited(context);
    }
;
