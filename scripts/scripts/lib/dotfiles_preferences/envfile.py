"""Keep user-authored shell content intact; never execute it during editing."""
import os
import re
import shlex
import subprocess

BEGIN = '# >>> dotfiles managed preferences >>>'
END = '# <<< dotfiles managed preferences <<<'


class PreferenceError(ValueError):
    pass


def syntax_check(text):
    env = {k: v for k, v in os.environ.items() if k not in ('BASH_ENV', 'ENV')}
    env.update(LC_ALL='C', PYTHONUTF8='1')
    result = subprocess.run(['/bin/bash', '--noprofile', '--norc', '-n'], input=text,
                            text=True, capture_output=True, env=env, timeout=5)
    if result.returncode or result.stderr:
        # Diagnostics can contain private source text; do not echo them in previews.
        raise PreferenceError('personal.env has invalid shell syntax; it was not modified')


def user_content(text):
    """Remove only our EOF block; unknown content remains byte-for-byte intact."""
    syntax_check(text)
    starts = list(re.finditer(r'(?m)^' + re.escape(BEGIN) + r'\r?$', text))
    ends = list(re.finditer(r'(?m)^' + re.escape(END) + r'\r?$', text))
    if not starts and not ends:
        return text
    if len(starts) != 1 or len(ends) != 1 or starts[0].start() >= ends[0].start():
        raise PreferenceError('Ambiguous managed preferences block; file left untouched')
    start, end = starts[0].start(), ends[0].end()
    syntax_check(text[:start])  # A marker inside a quoted value/heredoc is not ours.
    if text[end:].strip():
        raise PreferenceError('Move user additions before the managed preferences block before updating')
    return text[:start]


def literal_assignments(text):
    """Read simple literals for migration/defaults, not arbitrary shell programs.

    shlex keeps quoted multiline assignments together. Dynamic known settings are
    reported to the caller, never sourced, evaluated, or partially reconstructed.
    """
    syntax_check(text)
    statements, pending = [], ''
    for line in text.splitlines(keepends=True):
        if not pending and (not line.strip() or line.lstrip().startswith('#')):
            continue
        pending += line
        if pending.rstrip('\r\n').endswith('\\'):
            continue
        try:
            syntax_check(pending)
        except PreferenceError:
            continue
        lexer = shlex.shlex(pending, posix=True, punctuation_chars=';&|()<>')
        lexer.whitespace_split = True
        lexer.commenters = '#'
        statements.append(list(lexer))
        pending = ''
    if pending.strip():
        raise PreferenceError('Cannot safely read shell statement; file left untouched')
    values, dynamic = {}, set()
    for tokens in statements:
        if not tokens:
            continue
        if tokens[0] == 'export':
            tokens = tokens[1:]
        if len(tokens) == 2 and tokens[0] == 'unset':
            values[tokens[1]] = None
            dynamic.discard(tokens[1])
            continue
        if not tokens:
            continue
        match = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)=(.*)$', tokens[0], re.S)
        if not match:
            for token in tokens:
                nested = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)=', token)
                if nested:
                    dynamic.add(nested.group(1))
                    values.pop(nested.group(1), None)
            continue
        key, value = match.groups()
        # A literal dollar sign is valid in regexes. Only known shell expansions
        # are supported when a legacy setting is read for effective preferences.
        other_variables = re.search(r'\$(?!HOME\b|\{HOME\})(?:[A-Za-z_({]|\d)', value)
        if len(tokens) != 1 or '`' in value or other_variables:
            dynamic.add(key)
            values.pop(key, None)
        else:
            values[key] = value
            dynamic.discard(key)
    return values, dynamic


def project(text, assignments):
    if not assignments and BEGIN not in text:
        syntax_check(text)
        return text
    user = user_content(text)
    if not assignments:
        return user
    separator = '' if user.endswith('\n') or not user else '\n'
    lines = [BEGIN, '# Generated from preferences.json; edit user settings above this block.']
    for key, value in sorted(assignments.items()):
        if not re.fullmatch(r'[A-Z][A-Z0-9_]*', key):
            raise PreferenceError('Invalid managed environment key')
        lines.append('unset ' + key if value is None else 'export ' + key + '=' + shlex.quote(value))
    result = user + separator + '\n'.join(lines + [END, ''])
    syntax_check(result)
    return result
