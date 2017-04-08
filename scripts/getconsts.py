#!/usr/bin/env python3
"""Get Constants from some dump."""
from collections import OrderedDict


def clean(arg):
    """Clean a line."""
    arg = arg.strip(' ')
    arg = arg.split(' ')[0]
    if arg != 'Name':
        return arg


def main():
    """Main Function."""
    with open('dump', 'r') as dump:
        raw = list(filter(None, map(clean, dump)))

    processed = OrderedDict()
    for item in raw:
        if item.endswith('\n'):
            currentkey = item.strip('\n')
            processed[currentkey] = list()
            continue
        processed[currentkey].append(item)

    with open('consts', 'w') as consts:
        for k, vs in processed.items():
            consts.write('-- ' + k + '\n')
            for v in vs:
                consts.write('"' + v + '",\n')


if __name__ == '__main__':
    main()
