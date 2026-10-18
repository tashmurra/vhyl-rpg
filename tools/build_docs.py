#!/usr/bin/env python3
"""Build the source-derived reference and searchable MkDocs site."""
from __future__ import annotations

import argparse
from copy import deepcopy
import html
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import unquote

from docscan import Symbol, parse_source

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ('lib/vhyl-rpg.t', 'lib/vhyl-rpg-report.t', 'lib/vhyl-rpg-resilience.t',
           'lib/vhyl-rpg-conflict.t', 'lib/vhyl-rpg-progression.t',
           'lib/vhyl-rpg-lite-characters.t', 'lib/vhyl-rpg-lite-catalogue.t',
           'lib/vhyl-rpg-lite-equipment.t', 'lib/vhyl-rpg-lite-health.t',
           'lib/vhyl-rpg-lite-combat.t', 'lib/vhyl-rpg-lite-exploration.t',
           'lib/vhyl-rpg-lite-traits.t')
SOURCES += ('lib/vhyl-rpg-expanded.t', 'lib/vhyl-rpg-expanded-characters.t',
            'lib/vhyl-rpg-expanded-skills.t', 'lib/vhyl-rpg-expanded-traits.t',
            'lib/vhyl-rpg-expanded-equipment.t', 'lib/vhyl-rpg-expanded-exploration.t',
            'lib/vhyl-rpg-expanded-development.t', 'lib/vhyl-rpg-expanded-templates.t',
            'lib/vhyl-rpg-expanded-campaign.t', 'lib/vhyl-rpg-expanded-social.t',
            'lib/vhyl-rpg-expanded-health.t', 'lib/vhyl-rpg-expanded-hazards.t',
            'lib/vhyl-rpg-expanded-combat.t', 'lib/vhyl-rpg-expanded-technology.t',
            'lib/vhyl-rpg-expanded-creatures.t')
REPOSITORY = 'https://github.com/tashmurra/vhyl-rpg'
PUBLIC = {
    'Thing', 'RpgError', 'RpgSkill', 'RpgTraining', 'RpgTrait', 'RpgProfile',
    'RpgChallenge', 'RpgApproach', 'RpgContext', 'RpgCalculation', 'RpgAssessment',
    'RpgResult', 'RpgAttempt', 'rpgLedger', 'rpgRandom', 'rpgCheck', 'rpgPrepare',
    'rpgResolve', 'rpgPublish', 'RpgDisclosure', 'rpgFullDisclosure', 'RpgOdds',
    'rpgAssess', 'rpgOddsFor', 'rpgRecordedResult', 'rpgPublishAssessment',
    'rpgPublishRoll', 'rpgST', 'rpgDX', 'rpgIQ', 'rpgHT', 'rpgWill', 'rpgPerception',
    'rpgSpendTime', 'RpgBody', 'RpgCareResult', 'RpgTreatment', 'rpgInjuryFor',
    'rpgWound', 'rpgTreat', 'rpgRest', 'rpgRecoverStun', 'rpgPublishBody',
    'RpgDisposition', 'RpgSocialApproach', 'RpgCombatant', 'RpgConflict', 'RpgStrike',
    'RpgConflictResult', 'rpgBeginConflict', 'rpgConflictStep', 'rpgPublishConflict',
    'RpgMilestone', 'RpgAward', 'RpgDevelopment', 'RpgProgressResult',
    'rpgAwardMilestone', 'rpgAssessDevelopment', 'rpgDevelop', 'rpgPublishProgress',
}


def slug(value: str) -> str:
    return re.sub(r'[^A-Za-z0-9_]+', '-', value).strip('-')


def symbol_file(sym: Symbol) -> str:
    # RpgContext and rpgContext must coexist on case-insensitive filesystems.
    prefix = 'function-' if sym.kind == 'function' else ''
    return prefix + slug(sym.name) + '.md'


def merge_symbols(declarations: list[Symbol]) -> list[Symbol]:
    """Merge extensions, retaining every member's original source location."""
    output: dict[str, Symbol] = {}
    for item in deepcopy(declarations):
        if item.kind == 'macro':
            continue
        entries = [item]
        if item.kind == 'enum':
            entries = []
            for name in item.signature.removeprefix('enum ').split(','):
                entry = deepcopy(item)
                entry.name = name.strip()
                entry.description = 'Attribute identifier accepted by RpgProfile.attributeScore().'
                entries.append(entry)
        for sym in entries:
            if sym.kind == 'modify':
                if sym.name in output:
                    output[sym.name].members.extend(sym.members)
                    continue
                sym.kind = 'extension'
            elif sym.name in output:
                raise ValueError(f'duplicate declaration: {sym.name}')
            output[sym.name] = sym
    return list(output.values())


def model(root: Path = ROOT) -> list[Symbol]:
    declarations = []
    for source in SOURCES:
        declarations.extend(parse_source(source, (root / source).read_text(encoding='utf-8')))
    symbols = merge_symbols(declarations)
    named = {sym.name: sym for sym in symbols}
    missing = PUBLIC - named.keys()
    if missing:
        raise ValueError(f'missing public declarations: {sorted(missing)}')
    anchors = [symbol_file(sym).casefold() for sym in symbols]
    if len(anchors) != len(set(anchors)):
        raise ValueError('duplicate symbol URL')
    for sym in symbols:
        public = sym.name in PUBLIC or sym.name.startswith(('RpgLite', 'rpgLite', 'RpgExpanded', 'rpgExpanded'))
        sym.audience = 'author / trusted game code' if public else 'internal helper'
        if public and not sym.description:
            raise ValueError(f'public declaration lacks a description: {sym.name}')
    return symbols


def source_link(source: str, line: int) -> str:
    return f'source/{slug(source)}.md#L{line}'


def inherited_members(sym: Symbol, named: dict[str, Symbol]) -> dict[str, str]:
    inherited = {}
    seen = {m.name for m in sym.members}
    ancestors = {sym.name}
    parent = sym.parent
    while parent in named:
        if parent in ancestors:
            raise ValueError(f'inheritance cycle at {parent}')
        ancestors.add(parent)
        for member in named[parent].members:
            if member.name not in seen:
                inherited[member.name] = parent
                seen.add(member.name)
        parent = named[parent].parent
    return inherited


def symbol_page(sym: Symbol, named: dict[str, Symbol]) -> str:
    page = [f'# {sym.name}', '', f'**{sym.kind.title()}** · {sym.audience}', '',
            f'`{sym.signature}` · [Source]({source_link(sym.source, sym.line)})', '',
            sym.description or 'Implementation helper; its signature is indexed for source navigation.', '',
            '[Authoring guide](../docs/authoring.md) · [Reporting guide](../docs/reporting.md) · '
            '[Reference index](index.md)', '']
    if sym.kind == 'extension':
        page += ['Only members added by vhyl-rpg are listed here. The base type is supplied by '
                 '[vhyl](https://tashmurra.github.io/vhyl/).', '']
    if sym.parent:
        parent = (f'[{sym.parent}]({symbol_file(named[sym.parent])})' if sym.parent in named
                  else f'`{sym.parent}` (external)')
        page += [f'**Superclass:** {parent}', '']
    children = sorted(s.name for s in named.values() if s.parent == sym.name)
    if children:
        page += ['**Derived declarations:** ' + ', '.join(f'[{n}]({symbol_file(named[n])})' for n in children), '']
    grouped = {}
    for member in sym.members:
        grouped.setdefault(member.name, []).append(member)
    if grouped:
        page += ['## Declared members', '']
        for name in sorted(grouped, key=str.casefold):
            page.append(f'- [{name}](#member-{slug(name)}) — {grouped[name][-1].kind}')
        page.append('')
    inherited = inherited_members(sym, named)
    if inherited:
        page += ['## Inherited members', '']
        for name, owner in sorted(inherited.items(), key=lambda pair: pair[0].casefold()):
            page.append(f'- [{name}]({symbol_file(named[owner])}#member-{slug(name)}) from '
                        f'[{owner}]({symbol_file(named[owner])})')
        page.append('')
    for name in sorted(grouped, key=str.casefold):
        page += [f'<a id="member-{slug(name)}"></a>', f'## {name}', '']
        for member in grouped[name]:
            page += [f'`{member.signature}` · [Source]({source_link(member.source, member.line)})', '']
            if member.description:
                page += [member.description, '']
    return '\n'.join(page)


def render(symbols: list[Symbol], stage: Path, revision: str, root: Path = ROOT) -> None:
    stage.mkdir(parents=True, exist_ok=True)
    shutil.copy2(root / 'README.md', stage / 'index.md')
    shutil.copytree(root / 'docs', stage / 'docs', dirs_exist_ok=True)
    for guide in (stage / 'docs').rglob('*.md'):
        content = guide.read_text(encoding='utf-8').replace('](../README.md)', '](../index.md)')
        guide.write_text(content, encoding='utf-8')
    for name in ('dependencies.json', 'LICENSE', 'THIRD_PARTY_NOTICES.md'):
        shutil.copy2(root / name, stage / name)
    for source in (root / 'examples').rglob('*'):
        if source.is_file() and source.suffix in ('.py', '.t'):
            target = stage / source.relative_to(root)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
    reference = stage / 'reference'
    (reference / 'source').mkdir(parents=True, exist_ok=True)
    for source in SOURCES:
        page = [f'# {source}', '', '[Reference index](../index.md) · '
                f'[View on GitHub]({REPOSITORY}/blob/{revision}/{source})', '', '<pre class="source">']
        for number, line in enumerate((root / source).read_text(encoding='utf-8').splitlines(), 1):
            page.append(f'<span id="L{number}"><a href="#L{number}">{number:4}</a>  {html.escape(line)}</span>')
        page += ['</pre>', '']
        (reference / 'source' / f'{slug(source)}.md').write_text('\n'.join(page), encoding='utf-8')
    named = {sym.name: sym for sym in symbols}
    for sym in symbols:
        page = symbol_page(sym, named)
        page += f'\n[GitHub source]({REPOSITORY}/blob/{revision}/{sym.source}#L{sym.line})\n'
        (reference / symbol_file(sym)).write_text(page, encoding='utf-8')
    index = [
        '# Library reference', '', 'Source-linked API reference for the versioned library.', '',
        'Declarations, signatures, property defaults and adjacent comments are extracted from the '
        'library modules. Extensions are merged into their declaring type and retain their '
        'own source links. Member indexes cover declared members; type pages also show local inheritance.', '',
        'The guides describe behavior and disclosure requirements. Trusted assessment objects may '
        'contain hidden information: publish the redacted event envelopes to a player-facing host.', '',
        '[Classes and objects](types.md) · [Functions](functions.md) · '
        '[Alphabetical symbols](symbols.md) · [Alphabetical members](members.md)', '',
        f'Built from [revision `{revision}`]({REPOSITORY}/tree/{revision}).', '',
    ]
    groups = {'Core mechanics': SOURCES[0], 'Optional reporting': SOURCES[1],
              'Playable resilience': SOURCES[2], 'Physical and social conflicts': SOURCES[3],
              'Progression': SOURCES[4]}
    for label, source in groups.items():
        index += [f'## {label}', '']
        for sym in sorted(symbols, key=lambda s: s.name.casefold()):
            if sym.source == source and sym.name in PUBLIC:
                index.append(f'- [{sym.name}]({symbol_file(sym)}) — {sym.description}')
        index.append('')
    (reference / 'index.md').write_text('\n'.join(index), encoding='utf-8')
    for filename, title, selected in (
        ('symbols', 'Alphabetical symbols', symbols),
        ('types', 'Classes, objects and extensions', [s for s in symbols if s.kind in ('class', 'object', 'extension')]),
        ('functions', 'Functions', [s for s in symbols if s.kind == 'function']),
    ):
        page = [f'# {title}', '', '[Reference index](index.md)', '']
        for sym in sorted(selected, key=lambda s: s.name.casefold()):
            page.append(f'- [{sym.name}]({symbol_file(sym)}) — {sym.kind}; {sym.audience}')
        (reference / f'{filename}.md').write_text('\n'.join(page) + '\n', encoding='utf-8')
    page = ['# Alphabetical members', '', '[Reference index](index.md)', '']
    rows = [(m.name, sym.name) for sym in symbols for m in sym.members]
    for name, owner in sorted(set(rows), key=lambda row: (row[0].casefold(), row[1].casefold())):
        page.append(f'- [{name}]({symbol_file(named[owner])}#member-{slug(name)}) — {owner}')
    (reference / 'members.md').write_text('\n'.join(page) + '\n', encoding='utf-8')


def check_links(stage: Path) -> None:
    """Validate local Markdown targets and explicit source/member anchors."""
    errors = []
    for page in stage.rglob('*.md'):
        content = page.read_text(encoding='utf-8')
        for href in re.findall(r'\[[^]]*\]\(([^)]+)\)', content):
            if '://' in href or href.startswith('mailto:'):
                continue
            path, _, fragment = unquote(href).partition('#')
            target = (page.parent / path).resolve() if path else page.resolve()
            if not target.is_relative_to(stage.resolve()) or not target.is_file():
                errors.append(f'{page.relative_to(stage)}: missing {href}')
                continue
            if fragment and target.suffix == '.md':
                target_text = target.read_text(encoding='utf-8')
                ids = set(re.findall(r'<(?:a|span) id="([^"]+)"', target_text))
                ids.update(slug(h).lower() for h in re.findall(r'^#{1,6}\s+(.+)$', target_text, re.M))
                if fragment not in ids:
                    errors.append(f'{page.relative_to(stage)}: missing anchor {href}')
    if errors:
        raise ValueError('broken documentation links:\n' + '\n'.join(errors[:30]))


def build(stage: Path, site: Path, config: Path, revision: str) -> int:
    symbols = model()
    if stage.exists():
        shutil.rmtree(stage)
    render(symbols, stage, revision)
    check_links(stage)
    subprocess.run([sys.executable, '-m', 'mkdocs', 'build', '--strict', '--clean',
                    '--config-file', str(config), '--site-dir', str(site)], cwd=ROOT, check=True)
    print(f'{len(symbols)} declarations indexed; documentation build passed', flush=True)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='build in a temporary directory')
    parser.add_argument('--revision', help='Git revision for published source links; defaults to HEAD')
    args = parser.parse_args()
    revision = args.revision or subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    if not re.fullmatch(r'[A-Za-z0-9_./-]+', revision):
        raise ValueError('invalid source revision')
    if args.check:
        with tempfile.TemporaryDirectory(prefix='vhyl-rpg-docs-') as directory:
            folder = Path(directory)
            config = folder / 'mkdocs.yml'
            content = (ROOT / 'mkdocs.yml').read_text(encoding='utf-8')
            content = content.replace('docs_dir: build/docs-src', f'docs_dir: {folder / "docs-src"}')
            content = content.replace('site_dir: build/site', f'site_dir: {folder / "site"}')
            config.write_text(content, encoding='utf-8')
            return build(folder / 'docs-src', folder / 'site', config, revision)
    return build(ROOT / 'build/docs-src', ROOT / 'build/site', ROOT / 'mkdocs.yml', revision)


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f'vhyl-rpg docs: {error}', file=sys.stderr)
        raise SystemExit(1)
