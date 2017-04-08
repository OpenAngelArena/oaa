#!/usr/bin/env python3
"""Get Dota 2 Scripting API Functions and Constants."""
from bs4 import BeautifulSoup
import requests
import sys
import codecs
from collections import OrderedDict
from functools import partial


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


def cleanBlock(elem, table):
    """Return a clean block."""
    block = dict()
    for row in table('tr'):
        key = row.find_next('td').a
        value = key.find_next(elem)
        block[key.string.strip()] = value.string.strip()
    return block


def display(output, blocks):
    """Format and print blocks to output."""
    for k, vs in blocks.items():
        output.write('-- ' + k + '\n')
        for v in vs:
            output.write('"' + v + '",\n')


def main():
    """Main Function."""
    cleanConstBlock = partial(cleanBlock, 'td')
    cleanFuncBlock = partial(cleanBlock, 'code')

    page = getHTML(URL)
    if not page:
        print("Error Page not found.")
        exit(127)

    soup = BeautifulSoup(page, 'html.parser')
    blocks = OrderedDict()

    for span in soup('span', {'class': 'mw-headline'}):
        if not span.parent.next_sibling:
            continue
        name, table = getBlock(span)
        header = table.find_next('th').string.strip()
        if "Name" in header:
            blocks[name] = cleanConstBlock(table)
        elif "Function" in header:
            blocks[name] = cleanFuncBlock(table)

    display(sys.stdout, blocks)


if __name__ == '__main__':
    main()
