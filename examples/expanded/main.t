#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-dialogue.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded-all.t>

workshop: Room 'Signal Workshop'
    desc { return workshopSay('A damaged signal chart lies beside a practice receiver. Try study, decode, rest day, or status. Careful preparation takes longer and improves your chance.'); }
;
mentor: Actor 'mentor' location(workshop) vocab = 'mentor';
workshopRules: RpgExpandedRules;
analyst: RpgExpandedProfile actor = player rules = workshopRules iq = 12
    hpAdjustment = 1 skills = [analysisTraining] pointBudget = 100 developmentOpen = true;
analysis: RpgExpandedSkill id = 'signal-analysis' attribute = rpgIQ difficulty = 3;
analysisTraining: RpgExpandedTraining skill = analysis points = 4;
practice: RpgExpandedStudy profile = analyst training = analysisTraining permitted = true;
workshopProgress: object decoded = nil;
workshopSay(text) { event('survey.text'); eventValue(text); return nil; }
workshopStatus()
{
    workshopSay('Signal analysis: <<analyst.skillScore(analysis)>>. Invested points: <<analysisTraining.points>>. Study credit: <<practice.credit>> quarter learning-seconds.');
    workshopSay('Elapsed seconds: <<rpgLedger.seconds>>. Chart decoded: <<workshopProgress.decoded ? 'yes' : 'no'>>.');
    return nil;
}
workshopDo(code)
{
    if (code == 1200) return workshopStatus();
    if (code == 1201)
    {
        local result = practice.advance(3600);
        workshopSay(result.status == 'resolved' ? 'You spend an hour studying the receiver.' : result.reason);
    }
    if (code == 1202)
    {
        if (workshopProgress.decoded) return workshopSay('You have already decoded the chart.');
        local timing = new RpgExpandedTaskTime(); timing.baseSeconds = 60;
        timing.steps = 2; timing.applicable = true;
        local assessment = timing.assess(workshopRules);
        local context = new RpgLiteContext(); context.skill = analysis; context.modifier = assessment.modifier;
        local check = rpgLiteCheck(analyst,context); rpgSpendTime(assessment.seconds);
        if (check.achieved) workshopProgress.decoded = true;
        workshopSay(check.achieved ? 'The chart reveals a safe path through the marsh.' : 'The signal remains unclear after four minutes of careful work.');
    }
    if (code == 1203) { rpgSpendTime(86400); workshopSay('A quiet day passes.'); }
    return workshopStatus();
}
class WorkshopAction: Action code = 1200 exec(context) { return workshopDo(self.code); };
workshopStatusAction: WorkshopAction code = 1200;
workshopStudyAction: WorkshopAction code = 1201;
workshopDecodeAction: WorkshopAction code = 1202;
workshopRestAction: WorkshopAction code = 1203;
workshopStatusVerb: Verb code = 1200 action = workshopStatusAction label = 'workshop-status';
workshopStudyVerb: Verb code = 1201 action = workshopStudyAction label = 'workshop-study';
workshopDecodeVerb: Verb code = 1202 action = workshopDecodeAction label = 'workshop-decode';
workshopRestVerb: Verb code = 1203 action = workshopRestAction label = 'workshop-rest';
grammar command(workshopStatusCmd): 'status' : Command action = workshopStatusAction;
grammar command(workshopStudyCmd): 'study' : Command action = workshopStudyAction;
grammar command(workshopDecodeCmd): 'decode' : Command action = workshopDecodeAction;
grammar command(workshopRestCmd): 'rest' 'day' : Command action = workshopRestAction;
workshopPlan: Conversation id = 'workshop-plan' target = mentor choices = [studyChoice,decodeChoice,restChoice];
class WorkshopChoice: DialogueChoice
    code = 1200
    selected(context) { return workshopDo(self.code); }
;
studyChoice: WorkshopChoice id = 'study' labelId = 'workshop.study' code = 1201;
decodeChoice: WorkshopChoice id = 'decode' labelId = 'workshop.decode' code = 1202;
restChoice: WorkshopChoice id = 'rest' labelId = 'workshop.rest' code = 1203;
studyLabel: Message id = 'workshop.study' text = 'Study the receiver';
decodeLabel: Message id = 'workshop.decode' text = 'Decode the chart';
restLabel: Message id = 'workshop.rest' text = 'Rest for a day';
modify gameMain initialRoom = workshop;
startup() { rpgExpandedValidateCharacter(analyst); rpgRandom.seed(27); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args) { if (verb == 1200) return workshopStatus(); return vhylAct(verb,args); }
