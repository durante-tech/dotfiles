#!/usr/bin/env python3
"""Check built internal pages, assets, and fragment links without network access."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit
import sys

root = Path(__file__).resolve().parents[1] / 'dist'


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.ids = set()
        self.links = []
        self.feed(path.read_text())

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if tag == 'a' and 'href' in attrs:
            self.links.append(attrs['href'])


pages = {path: Page(path) for path in root.rglob('*.html')}
errors = set()
for source, page in pages.items():
    route = '/' + str(source.relative_to(root)).removesuffix('index.html')
    for link in page.links:
        url = urlsplit(urljoin('http://fixture' + route, link))
        if url.netloc != 'fixture' or url.scheme not in ['http', 'https']:
            continue
        target = root / unquote(url.path).lstrip('/')
        if target.is_dir():
            target /= 'index.html'
        if not target.is_file():
            errors.add(f'{route} -> {link}: missing page or asset')
        elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
            errors.add(f'{route} -> {link}: missing anchor')
for error in sorted(errors):
    print(error)
print(f'Checked {len(pages)} pages; {len(errors)} broken links')
sys.exit(bool(errors) or not pages)
