#!/usr/bin/env python3
"""Get Dota 2 Scripting API Functions and Constants."""
from bs4 import BeautifulSoup
import requests
import sys
import codecs
from collections import OrderedDict
from functools import partial
import os


ENCODING = "utf-8"
ENCODING_MODE = "replace"
if sys.stdout.encoding != ENCODING:
    sys.stdout = codecs.getwriter(ENCODING)(sys.stdout.buffer, ENCODING_MODE)
if sys.stderr.encoding != ENCODING:
    sys.stderr = codecs.getwriter(ENCODING)(sys.stderr.buffer, ENCODING_MODE)


URL = 'https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/\
Scripting/API'


def getHTML(url):
    """Return a downloaded HTML file."""
    r = requests.get(url)
    if r.ok:
        return r.content.decode(ENCODING)
    return None


def getBlock(span):
    """Return a unpacked block."""
    return (span.string, span.find_next('table'))


def cleanBlock(table, elem, nested):
    """Return a clean block."""
    block = dict()
    for row in table('tr'):
        key = row.find_next('td')
        if nested:
            key = key.a
        value = key.find_next(elem)
        block[key.string.strip()] = value.string.strip()
    return block


def getAPIRefs():
    """Get API Refs from valve and return a block"""
    cleanConstBlock = partial(cleanBlock, elem='td', nested=False)
    cleanFuncBlock = partial(cleanBlock, elem='code', nested=True)

    page = getHTML(URL)
    if not page:
        print("Error Page not found.")
        exit(127)

    soup = BeautifulSoup(page, 'html.parser')
    blocks = OrderedDict()
    blocks['Accessor'] = list()

    for span in soup('span', {'class': 'mw-headline'}):
        if not span.parent.next_sibling:
            continue
        name, table = getBlock(span)
        header = table.find_next('th').string.strip()
        if "Name" in header:
            blocks[name] = cleanConstBlock(table)
        elif "Function" in header:
            blocks[name] = cleanFuncBlock(table)
            blocks['Accessor'].append(name)

    return blocks


def getRequirePath(line):
    for item in line.split('require'):
        item = item.strip()
        if not item:
            continue
        if item.startswith('(') and item.endswith(')'):
            return item.strip('()"\'')


def getRequired(filename):
    result = list()
    if not filename.endswith('.lua'):
        return
    with open(filename, 'r') as luafile:
        for line in luafile:
            if "require" not in line:
                continue
            required = getRequirePath(line)
            if not required:
                continue
            required = os.path.join("game/scripts/vscripts/", required)
            result.append(required)
    return result


def getVScriptGlobals():
    """Go through game/scripts/vscripts and follow require."""
    blocks = dict()
    filestoadd = list()
    filestocheck = list()
    for _, _, filenames in os.walk("game/scripts/vscripts/"):
        for filename in filenames:
            filename = os.path.join("game/scripts/vscripts/", filename)
            required = getRequired(filename)
            filestoadd += required
            filestocheck += required
        break
    while filestoadd:
        for entry in filestoadd:
            print(entry)
            entry = os.path.join("game/scripts/vscripts/", entry)
            required = getRequired(entry)
            if not required:
                continue
            filestoadd += required
            filestocheck += required
            filestoadd.remove(entry)
    print(repr(filestoadd))
    print(repr(filestocheck))
    return blocks


def display(output, blocks):
    """Format and print blocks to output."""
    for k, vs in blocks.items():
        output.write('-- ' + k + '\n')
        for v in vs:
            output.write('"' + v + '",\n')


def main():
    """Main Function."""
    blocks = OrderedDict()
    blocks = OrderedDict(blocks, **getAPIRefs())
    blocks = OrderedDict(blocks, **getVScriptGlobals())

    with open('dump', 'w') as dump:
        # display(dump, blocks)
        pass

    return 0


if __name__ == '__main__':
    main()
