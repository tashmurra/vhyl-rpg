/** Numeric trait, skill, armor and shield catalogue from Lite; factories create independent owned objects. */
rpgLiteCatalogue: object
    traits = [
        ['acute-hearing', 2, 100, nil], ['acute-vision', 2, 100, nil],
        ['acute-touch', 2, 100, nil], ['acute-taste-smell', 2, 100, nil],
        ['ambidexterity', 5, 1, nil], ['animal-empathy', 5, 1, nil],
        ['catfall', 10, 1, nil], ['combat-reflexes', 15, 1, nil],
        ['danger-sense', 15, 1, nil], ['daredevil', 15, 1, nil],
        ['empathy', 15, 1, nil], ['enhanced-block', 5, 1, nil],
        ['enhanced-dodge', 15, 1, nil], ['enhanced-parry', 5, 1, nil],
        ['enhanced-parry-all', 10, 1, nil], ['fearlessness', 2, 100, nil],
        ['flexibility', 5, 1, nil], ['double-jointed', 15, 1, nil],
        ['hard-to-kill', 2, 100, nil], ['high-pain-threshold', 10, 1, nil],
        ['jumper-time', 100, 1, nil], ['jumper-world', 100, 1, nil],
        ['language-talent', 10, 1, nil], ['luck', 15, 1, nil],
        ['extraordinary-luck', 30, 1, nil], ['ridiculous-luck', 60, 1, nil],
        ['night-vision', 1, 9, nil], ['perfect-balance', 15, 1, nil],
        ['resistant-disease-3', 3, 1, nil], ['resistant-disease-8', 5, 1, nil],
        ['resistant-poison-3', 5, 1, nil], ['artificer', 10, 4, nil],
        ['outdoorsman', 10, 4, nil], ['smooth-operator', 15, 4, nil],
        ['bad-sight-correctable', -10, 1, nil], ['bad-sight', -25, 1, nil],
        ['bad-temper', -10, 1, true], ['bloodlust', -10, 1, true],
        ['code-of-honor', -5, 3, nil], ['curious', -5, 1, true],
        ['delusions', -5, 3, nil], ['gluttony', -5, 1, true],
        ['greed', -15, 1, true], ['hard-of-hearing', -10, 1, nil],
        ['honesty', -10, 1, true], ['impulsiveness', -10, 1, true],
        ['intolerance', -1, 10, nil], ['jealousy', -10, 1, nil],
        ['lecherousness', -15, 1, true], ['obsession', -5, 2, true],
        ['overconfidence', -5, 1, true], ['reluctant-killer', -5, 1, nil],
        ['cannot-harm-innocents', -10, 1, nil], ['phobia-blood', -10, 1, true],
        ['phobia-darkness', -15, 1, true], ['phobia-heights', -10, 1, true],
        ['phobia-thirteen', -5, 1, true], ['phobia-spiders', -5, 1, true],
        ['duty-individual', -2, 1, nil], ['duty-small-group', -5, 1, nil],
        ['duty-large-group', -10, 1, nil], ['duty-race', -15, 1, nil],
        ['duty-all-life', -20, 1, nil], ['truthfulness', -5, 1, true],
        ['unluckiness', -10, 1, nil], ['vow', -5, 3, nil], ['quirk', -1, 1, nil],
        ['hideous', -16, 1, nil], ['ugly', -8, 1, nil], ['unattractive', -4, 1, nil],
        ['attractive', 4, 1, nil], ['handsome', 12, 1, nil], ['very-handsome', 16, 1, nil],
        ['charisma', 5, 100, nil], ['voice', 10, 1, nil], ['odious-habits', -5, 3, nil],
        ['status', 5, 8, nil], ['low-status', -5, 2, nil],
        ['reputation', 5, 4, nil], ['bad-reputation', -5, 4, nil],
        ['dead-broke', -25, 1, nil], ['poor', -15, 1, nil], ['struggling', -10, 1, nil],
        ['comfortable', 10, 1, nil], ['wealthy', 20, 1, nil],
        ['very-wealthy', 30, 1, nil], ['filthy-rich', 50, 1, nil]
    ]
    skills = [
        ['acrobatics', rpgDX, 2, -6, nil], ['acting', rpgIQ, 1, -5, nil],
        ['animal-handling', rpgIQ, 1, -5, nil], ['area-knowledge', rpgIQ, 0, -4, nil],
        ['armoury', rpgIQ, 1, -5, true], ['brawling', rpgDX, 0, nil, nil],
        ['camouflage', rpgIQ, 0, -4, nil], ['carousing', rpgHT, 0, -4, nil],
        ['climbing', rpgDX, 1, -5, nil], ['computer-operation', rpgIQ, 0, -4, true],
        ['computer-programming', rpgIQ, 2, nil, true], ['crewman', rpgIQ, 0, -4, true],
        ['criminology', rpgIQ, 1, -5, true], ['diagnosis', rpgIQ, 2, -6, true],
        ['disguise', rpgIQ, 1, -5, true], ['electronics-operation', rpgIQ, 1, -5, true],
        ['electronics-repair', rpgIQ, 1, -5, true], ['engineer', rpgIQ, 2, nil, true],
        ['environment-suit', rpgDX, 1, -5, true], ['escape', rpgDX, 2, -6, nil],
        ['explosives', rpgIQ, 1, -5, true], ['first-aid', rpgIQ, 0, -4, true],
        ['forgery', rpgIQ, 2, -6, true], ['gambling', rpgIQ, 1, -5, nil],
        ['hiking', rpgHT, 1, -5, nil], ['holdout', rpgIQ, 1, -5, nil],
        ['humanities', rpgIQ, 2, -6, nil], ['diplomacy', rpgIQ, 2, -6, nil],
        ['fast-talk', rpgIQ, 1, -5, nil], ['intimidation', rpgIQ, 1, -5, nil],
        ['savoir-faire', rpgIQ, 0, -4, nil], ['sex-appeal', rpgHT, 1, -3, nil],
        ['streetwise', rpgIQ, 1, -5, nil], ['interrogation', rpgIQ, 1, -5, nil],
        ['jumping', rpgDX, 0, nil, nil], ['karate', rpgDX, 2, nil, nil],
        ['law', rpgIQ, 2, -6, nil], ['leadership', rpgIQ, 1, -5, nil],
        ['lockpicking', rpgIQ, 1, -5, true], ['mathematics', rpgIQ, 2, -6, true],
        ['mechanic', rpgIQ, 1, -5, true], ['rapier', rpgDX, 1, -5, nil],
        ['smallsword', rpgDX, 1, -5, nil], ['flail', rpgDX, 2, -6, nil],
        ['axe-mace', rpgDX, 1, -5, nil], ['polearm', rpgDX, 1, -5, nil],
        ['spear', rpgDX, 1, -5, nil], ['staff', rpgDX, 1, -5, nil],
        ['broadsword', rpgDX, 1, -5, nil], ['knife', rpgDX, 0, -4, nil],
        ['shortsword', rpgDX, 1, -5, nil], ['two-handed-sword', rpgDX, 1, -5, nil],
        ['merchant', rpgIQ, 1, -5, nil], ['gunner', rpgDX, 0, -4, true],
        ['guns', rpgDX, 0, -4, true], ['flamethrower', rpgDX, 0, -4, nil],
        ['blowpipe', rpgDX, 2, -6, nil], ['bow', rpgDX, 1, -5, nil],
        ['crossbow', rpgDX, 0, -4, nil], ['natural-sciences', rpgIQ, 2, -6, true],
        ['naturalist', rpgIQ, 2, -6, nil], ['navigation', rpgIQ, 1, -5, true],
        ['observation', rpgIQ, 1, -5, nil], ['occultism', rpgIQ, 1, -5, nil],
        ['photography', rpgIQ, 1, -5, true], ['physician', rpgIQ, 2, -7, true],
        ['pickpocket', rpgDX, 2, -6, nil], ['public-speaking', rpgIQ, 1, -5, nil],
        ['research', rpgIQ, 1, -5, true], ['riding', rpgDX, 1, -5, nil],
        ['scrounging', rpgIQ, 0, -4, nil], ['search', rpgIQ, 1, -5, nil],
        ['shadowing', rpgIQ, 1, -5, nil], ['shield', rpgDX, 0, -4, nil],
        ['social-sciences', rpgIQ, 2, -6, nil], ['smuggling', rpgIQ, 1, -5, nil],
        ['stealth', rpgDX, 1, -5, nil], ['survival', rpgIQ, 1, -5, nil],
        ['swimming', rpgHT, 0, -4, nil], ['tactics', rpgIQ, 2, -6, nil],
        ['throwing', rpgDX, 1, -3, nil], ['thrown-weapon', rpgDX, 0, -4, nil],
        ['tracking', rpgIQ, 1, -5, nil], ['traps', rpgIQ, 1, -5, true],
        ['bicycling', rpgDX, 0, -4, nil], ['boating', rpgDX, 1, -5, nil],
        ['driving', rpgDX, 1, -5, nil], ['piloting', rpgDX, 1, -5, nil],
        ['submarine', rpgDX, 1, -5, nil], ['writing', rpgIQ, 1, -5, nil]
    ]
    armor = [
        ['cloth', 1, 150, 1200], ['leather', 2, 340, 1950], ['light-scale', 3, 610, 4900],
        ['mail', 4, 645, 5800], ['steel-laminate', 5, 1360, 6400], ['plate', 6, 4040, 8950],
        ['flak-jacket', 7, 500, 2000], ['ballistic-vest', 8, 400, 200], ['tactical-vest', 12, 900, 900]
    ]
    shields = [['small-shield', 1, 40, 800], ['medium-shield', 2, 60, 1500], ['large-shield', 3, 90, 2500]]
;

/** Create a catalogue trait at a legal level and authored scope; unknown IDs throw. */
rpgLiteMakeTrait(id, level, scope)
{
    foreach (local row in rpgLiteCatalogue.traits)
        if (row[1] == id)
        {
            rpgInteger(level, 1, row[3]);
            local trait = new RpgLiteTrait(); trait.id = id; trait.labelId = id;
            trait.points = row[2]; trait.level = level; trait.controlled = row[4]; trait.scope = scope;
            return trait;
        }
    throw new RpgError();
}

/** Create a catalogue skill. Supply TL only for technological skills and a specialty where appropriate. */
rpgLiteMakeSkill(id, techLevel, specialty)
{
    foreach (local row in rpgLiteCatalogue.skills)
        if (row[1] == id)
        {
            if (row[5]) rpgInteger(techLevel, 0, 12);
            else if (techLevel != nil) throw new RpgError();
            local skill = new RpgLiteSkill(); skill.id = id; skill.labelId = id;
            skill.attribute = row[2]; skill.difficulty = row[3]; skill.defaultPenalty = row[4];
            skill.techLevel = techLevel; skill.specialty = specialty;
            skill.influence = holds(['diplomacy', 'fast-talk', 'intimidation', 'savoir-faire', 'sex-appeal', 'streetwise'], id);
            skill.voice = skill.influence || holds(['acting', 'public-speaking', 'leadership'], id);
            if (holds(['driving', 'piloting', 'submarine'], id)) skill.alternateAttribute = rpgIQ;
            return skill;
        }
    throw new RpgError();
}

/** Find the matching owned skill or create a default-only skill with the requested identity. */
rpgLiteTraining(profile, id, techLevel, specialty)
{
    foreach (local training in profile.skills)
        if (training.skill.ofKind(RpgLiteSkill) && training.skill.id == id
            && training.skill.techLevel == techLevel && training.skill.specialty == specialty) return training.skill;
    return rpgLiteMakeSkill(id, techLevel, specialty);
}

/** Calculate TL and wealth-adjusted starting money; mobile selects the full rather than 20% allowance. */
rpgLiteStartingWealth(profile, mobile)
{
    local amounts = [250, 500, 750, 1000, 2000, 5000, 10000, 15000, 20000, 30000, 50000, 75000, 100000];
    local amount = amounts[profile.campaignTL + 1];
    if (profile.level('dead-broke') > 0) return 0;
    if (profile.level('poor') > 0) amount /= 5;
    if (profile.level('struggling') > 0) amount /= 2;
    if (profile.level('comfortable') > 0) amount *= 2;
    if (profile.level('wealthy') > 0) amount *= 5;
    if (profile.level('very-wealthy') > 0) amount *= 20;
    if (profile.level('filthy-rich') > 0) amount *= 100;
    return mobile ? amount : amount / 5;
}
