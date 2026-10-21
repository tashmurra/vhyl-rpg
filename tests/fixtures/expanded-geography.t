#include "expanded-cultures.t"
modify crossPhysician nativePlanetType = 'habitable' traits = [] skills = [];
geographyPhysical: RpgExpandedGeographySkill specialty = 'physical' planetType = 'habitable' techLevel = 8;
geographyPolitical: RpgExpandedGeographySkill specialty = 'political' techLevel = 8;
geographyRegional: RpgExpandedGeographySkill specialty = 'regional' region = 'river-basin' techLevel = 8;
geographyRocky: RpgExpandedGeographySkill specialty = 'physical' planetType = 'rocky' techLevel = 8;
geographySource: RpgExpandedTraining skill = geographyPolitical points = 24;
geographyScience: RpgExpandedSkill id = 'geology' attribute = rpgIQ difficulty = 2 defaultPenalty = -6 techLevel = 8 specialty = 'habitable';
geographyScienceTraining: RpgExpandedTraining skill = geographyScience points = 24;
geographyTask: RpgExpandedGeographyContext skill = geographyPhysical topic = 'physical' planetType = 'habitable'
    approved = true evidence = 'A question about the basin climate';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 26900)
        { event('test.geography'); eventValue(rpgLiteScore(crossPhysician,geographyTask));
          eventValue(crossPhysician.skillScore(geographyRocky)); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 26901) { crossPhysician.skills = [geographySource]; return nil; }
        if (code == 26902) { geographySource.skill = geographyRocky; crossPhysician.skills = [geographySource]; return nil; }
        if (code == 26903) { crossPhysician.skills = [geographyScienceTraining]; return nil; }
        if (code == 26904) { geographyScience.specialty = 'rocky'; return nil; }
        if (code == 26905) { geographyTask.topic = 'political'; return nil; }
        if (code == 26906) { geographyTask.planetType = 'rocky'; return nil; }
        if (code == 26907)
        { geographyTask.skill = geographyRegional; geographyTask.topic = 'political'; geographyTask.region = 'river-basin'; geographyTask.depthApproved = true; return nil; }
        if (code == 26908) { geographyTask.region = 'other-basin'; return nil; }
        if (code == 26909) { geographyTask.depthApproved = nil; return nil; }
        if (code == 26910)
        { geographyTask.skill = geographyPolitical; geographyTask.topic = 'political'; geographyScience.id = 'economics';
          geographyScience.techLevel = nil; geographyScience.specialty = nil; crossPhysician.skills = [geographyScienceTraining]; return nil; }
        if (code == 26911)
        { geographyTask.skill = geographyRegional; geographyTask.topic = 'political'; geographyTask.region = 'river-basin';
          geographyTask.depthApproved = true; geographyScience.id = 'area-knowledge'; geographyScience.techLevel = nil;
          geographyScience.specialty = 'river-basin'; geographyScience.difficulty = 0; geographyScience.defaultPenalty = -4;
          crossPhysician.skills = [geographyScienceTraining]; return nil; }
        return inherited(context);
    }
;
