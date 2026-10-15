#!/usr/bin/env python3
"""Fetch the immutable complete ZIP using PUBLICATION.json from the receiver."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import urllib.request
import uuid

REPOSITORY = 'acidonion2010-lgtm/BINGO-BOUT-BREAK-BLOCK'
DIRECTORY = 'handoff/20261016'


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def safe_name(name):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+', name) or name in ('.', '..'):
        raise ValueError('Invalid published filename')
    return name


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--publication', type=Path, required=True)
    p.add_argument('--destination', type=Path, required=True)
    args = p.parse_args()
    publication = json.loads(args.publication.read_text(encoding='utf-8-sig'))
    revision = publication['Revision']
    if not re.fullmatch('[0-9a-fA-F]{40}', revision):
        raise ValueError('A fixed 40-character Git commit is required')
    base = f'https://raw.githubusercontent.com/{REPOSITORY}/{revision}/{DIRECTORY}/'
    with urllib.request.urlopen(base + 'manifest.json', timeout=90) as response:
        manifest_bytes = response.read()
    if hashlib.sha256(manifest_bytes).hexdigest().lower() != publication['ManifestSha256'].lower():
        raise ValueError('Published manifest checksum mismatch')
    manifest = json.loads(manifest_bytes)
    if manifest['schema'] != 1:
        raise ValueError('Unsupported manifest schema')
    args.destination.mkdir(parents=True, exist_ok=True)
    archive = manifest['archive']
    final = args.destination / safe_name(archive['name'])
    if final.exists():
        if final.stat().st_size == archive['bytes'] and sha(final) == archive['sha256'].lower():
            print(final)
            return
        raise FileExistsError('Different existing archive; no replacement: ' + str(final))
    parts = []
    for entry in manifest['parts']:
        path = args.destination / safe_name(entry['name'])
        if path.exists():
            if path.stat().st_size != entry['bytes'] or sha(path) != entry['sha256'].lower():
                raise FileExistsError('Different existing part: ' + str(path))
        else:
            temp = path.with_name(path.name + '.partial-' + uuid.uuid4().hex)
            try:
                with urllib.request.urlopen(base + entry['name'], timeout=90) as source, temp.open('xb') as out:
                    shutil.copyfileobj(source, out, 1024 * 1024)
                if temp.stat().st_size != entry['bytes'] or sha(temp) != entry['sha256'].lower():
                    raise ValueError('Part checksum mismatch: ' + entry['name'])
                os.link(temp, path)
            finally:
                temp.unlink(missing_ok=True)
        parts.append(path)
    temp = final.with_name(final.name + '.partial-' + uuid.uuid4().hex)
    try:
        with temp.open('xb') as out:
            for part in parts:
                with part.open('rb') as source:
                    shutil.copyfileobj(source, out, 1024 * 1024)
        if temp.stat().st_size != archive['bytes'] or sha(temp) != archive['sha256'].lower():
            raise ValueError('Complete ZIP checksum mismatch')
        os.link(temp, final)
    finally:
        temp.unlink(missing_ok=True)
    print(final)


if __name__ == '__main__':
    main()
