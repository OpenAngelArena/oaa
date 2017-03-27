#!/usr/bin/env python3
"""Display stats about oaa."""

import os

basedir = os.sep.join(os.path.realpath(__file__).split(os.sep)[:-2])
npcdir = os.path.join(basedir, "game", "scripts", "npc")
herolist = os.path.join(npcdir, "herolist.txt")

npcs = ["abilities", "heroes", "items", "units"]


def countLines(file, begin):
    """Count all lines in a file."""
    count = 0
    if os.path.exists(file):
        with open(file, 'r') as lines:
            for line in lines:
                if line.startswith(begin):
                    count += 1
    return count


def countFiles(dir):
    """Count all files in a directory."""
    count = 0
    for _, _, files in os.walk(dir):
        for file in files:
            count += 1
    return count


def display(npc, files, linked):
    """Display."""
    print("{}: {}/{}".format(npc, files, linked))


def main():
    """Main Function."""
    for npc in npcs:
        cwd = os.path.join(npcdir, npc)
        filecount = countFiles(cwd)
        custom = os.path.join(npcdir, "npc_" + npc + "_custom.txt")
        override = os.path.join(npcdir, "npc_" + npc + "_override.txt")
        linked = countLines(custom, "#base")
        linked += countLines(override, "#base")
        display(npc, filecount, linked)


if __name__ == '__main__':
    main()
