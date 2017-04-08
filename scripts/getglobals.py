#!/usr/bin/env python3
"""Get Dota 2 Scripting API Functions and Constants."""
from bs4 import BeautifulSoup
import requests
import sys
import codecs
from collections import OrderedDict


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
    else:
        return None


def getBlock(span):
    name = span.string
    block = span.find_next('table')
    return (name, block)


def cleanFuncBlock(table):
    block = dict()
    for row in table('tr'):
        key = row.find_next('td').a
        value = key.find_next('code')
        block[key.string.strip()] = value.string.strip()
    return block


def cleanConstBlock(table):
    block = dict()
    for row in table('tr'):
        key = row.find_next('td')
        value = key.find_next('td')
        block[key.string.strip()] = value.string.strip()
    return block


def display(output, blocks):
    for k, vs in blocks.items():
        output.write('-- ' + k + '\n')
        for v in vs:
            output.write('"' + v + '",\n')


def main():
    """Main Function."""
    page = getHTML(URL)
    if not page:
        print("Error Page not found.")
        exit(127)
    soup = BeautifulSoup(page, 'html.parser')
    blocks = OrderedDict()
    for span in soup('span', {'class': 'mw-headline'}):
        if span.parent.next_sibling:
            name, table = getBlock(span)
            header = table.find_next('th').string.strip()
            if "Name" in header:
                blocks[name] = cleanConstBlock(table)
            elif "Function" in header:
                blocks[name] = cleanFuncBlock(table)
    with open('dump', 'w', encoding=ENCODING) as dump:
        display(dump, blocks)


if __name__ == '__main__':
    main()
