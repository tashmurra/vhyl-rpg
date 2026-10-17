"""Example presentation of already-disclosed mechanics events."""

LABELS = {
    'survey.inspection': 'Inspection', 'survey.lockwork': 'Lockwork',
    'survey.negotiation': 'Negotiation', 'survey.careful-eye': 'Careful eye',
    'rpg.strength': 'Strength', 'rpg.coordination': 'Coordination',
    'rpg.intelligence': 'Intelligence', 'rpg.health': 'Health',
    'rpg.will': 'Will', 'rpg.perception': 'Perception',
    'rpg.modifier.situation': 'difficulty', 'rpg.modifier.preparation': 'preparation',
    'rpg.modifier.opposition': 'opposition',
    'rpg.modifier.opposition-preparation': 'opposition preparation',
    'rpg.modifier.other': 'other adjustments',
    'survey.uncertain': 'Outcome uncertain',
    'training-required': 'training required', 'too-difficult': 'better preparation required',
    'insufficient-energy': 'insufficient energy', 'survey.need-key': 'take the key first',
    'gate.first-aid': 'First aid', 'gate.brawling': 'Brawling', 'gate.negotiation': 'Negotiation',
    'gate.nerves': 'Nerves', 'gate.poise': 'Composure', 'gate.uncertain': 'Outcome uncertain',
    'rpg.modifier.shock': 'injury shock', 'rpg.modifier.exhaustion': 'exhaustion',
}
APPROACHES = {'inspect': 'Inspect panel', 'pick': 'Pick hatch', 'force': 'Force hatch',
              'persuade': 'Persuade keeper', 'key': 'Use key', 'parley': 'Negotiate passage'}
OUTCOMES = {'success': 'success', 'costly-success': 'success with a cost',
            'setback': 'goal not achieved', 'complication': 'complication', 'tie': 'tie'}


def percent(numerator, denominator):
    return f'{100 * numerator / denominator:.1f}%'


def calculation_line(c, states):
    _, source, goal, method, _, side, ability, attribute, training, attribute_score, default, base, effective, count, *modifiers = c
    label = LABELS.get(ability, LABELS.get(attribute, 'Ability'))
    if training == 'default':
        label += ' (untrained default)'
    elif training == 'unavailable':
        label += ' (training required)'
    text = label
    if base is not None:
        text += f' {base}'
        if default is not None:
            text += f' (from {attribute_score} {default:+d})'
        for i in range(count):
            category, key, amount = modifiers[i * 3:i * 3 + 3]
            text += f' {amount:+d} {LABELS.get(key, "adjustment")}'
        if effective is not None:
            text += f' = {effective}'
    prefix = 'Used' if source == 'roll' else ('Previous attempt used'
             if states.get((goal, method)) == 'settled' else 'Would use')
    if side == 'opposition':
        prefix = 'Opposition used' if source == 'roll' else 'Opposition would use'
    return f'{prefix}: {text}'


def report_lines(events):
    """Render no undisclosed values and never infer a hidden opponent's score."""
    calculations = [e['values'] for e in events if e['id'] == 'rpg.calculation']
    states = {(e['values'][1], e['values'][2]): e['values'][4]
              for e in events if e['id'] == 'rpg.assessment'}
    scores = {(c[1], c[2], c[3], c[5]): c[12] for c in calculations}
    lines = []
    for event in events:
        v = event['values']
        if event['id'] == 'rpg.strike':
            _, _, side, outcome, score, total, defense, damage, injury, own, other, harm, *faces = v
            text = ('Your attack' if side == 'acting' else 'Opponent attack') + ': '
            text += ' + '.join(map(str, faces[:own])) + f' = {total}, against {score} — {outcome}'
            lines.append(text)
            if other:
                lines.append('Defense: ' + ' + '.join(map(str, faces[own:own + other])) + f' = {defense}')
            if outcome == 'hit':
                lines.append(f'Damage {damage}; injury {injury}.')
        elif event['id'] == 'rpg.assessment':
            _, goal, method, _, status, reason, kind, seconds, energy, estimate, total, achieved, success, costly, *rest = v
            name = APPROACHES.get(method, 'Approach')
            if status in ('complete', 'settled'):
                text = 'already complete' if status == 'complete' else 'attempt already resolved'
            elif status == 'blocked':
                text = LABELS.get(reason, 'unavailable')
            elif total is not None:
                text = f'{percent(achieved, total)} chance of achieving the goal'
                if costly:
                    text += f' ({percent(costly, total)} with a cost)'
                if kind == 'automatic':
                    text = 'automatic success'
            elif estimate is not None:
                text = LABELS.get(estimate, 'Outcome uncertain')
            else:
                text = 'details withheld'
            if seconds:
                text += f' · {seconds}s'
            if energy:
                text += f' · {energy} energy'
            lines.append(f'{name}: {text}')
        elif event['id'] == 'rpg.calculation':
            lines.append(calculation_line(v, states))
        elif event['id'] == 'rpg.roll':
            _, goal, method, _, status, kind, outcome, achieved, seconds, energy, total, margin, critical, other, other_margin, other_critical, count, other_count, *faces = v
            if kind == 'automatic' and outcome is not None:
                lines.append('Automatic success; no dice rolled.')
                continue
            if count:
                text = '3d6: ' + ' + '.join(map(str, faces[:count])) + f' = {total}'
                score = scores.get(('roll', goal, method, 'acting'))
                if score is not None:
                    text += f', against {score}'
            else:
                text = ''
            if outcome is not None:
                text += (' — ' if text else '') + OUTCOMES.get(outcome, 'resolved')
            if margin is not None:
                text += f' (margin {margin:+d})'
            if text:
                lines.append(text)
            if other_count:
                dice = faces[(count or 0):(count or 0) + other_count]
                text = 'Opposition 3d6: ' + ' + '.join(map(str, dice)) + f' = {other}'
                score = scores.get(('roll', goal, method, 'opposition'))
                if score is not None:
                    text += f', against {score}'
                lines.append(text)
    return lines
