#!/usr/bin/env python3
"""
calc_packages_deps.py: Compute the transitive closure of prerequisites for one or more Make targets,
excluding any rules ending with "-setup".

Usage:
    python calc_packages_deps.py [-f MAKEFILE] TARGET [TARGET ...]

Options:
    -f, --file MAKEFILE  Specify a Makefile (default: use default Makefile search order)
"""
import argparse
import subprocess
import sys
import re
from collections import defaultdict, deque

def dump_make_database(makefile=None):
    cmd = ["make", "-qp"]
    if makefile:
        cmd.extend(["-f", makefile])
    try:
        # capture stdout even if 'make -qp' returns exit status 1 (needs remaking)
        output = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, universal_newlines=True)
    except subprocess.CalledProcessError as e:
        # make -qp may return code 1 if some targets are out of date, but still prints database
        if e.returncode == 1 and getattr(e, 'output', None):
            output = e.output
        else:
            sys.stderr.write(f"Error running make: exit code {e.returncode}\n")
            sys.exit(e.returncode)
    return output

def parse_rules(make_db_text):
    # Parse lines of form: target: prereq1 prereq2 ...
    rules = defaultdict(list)
    rule_re = re.compile(r'^([\w\-./]+):\s*(.*)$')
    for line in make_db_text.splitlines():
        m = rule_re.match(line)
        if m:
            target = m.group(1)
            # skip any -setup rules entirely
            if target.endswith('-setup'):
                continue
            deps = m.group(2)
            if deps:
                parts = deps.split()
                prereqs = [p for p in parts if p != '|' and not p.endswith('-setup')]
                rules[target].extend(prereqs)
    return rules

def compute_closure(rules, start):
    seen = set()
    order = []
    stack = deque([start])
    while stack:
        node = stack.pop()
        # skip exploring or listing -setup nodes
        if node.endswith('-setup'):
            continue
        for dep in rules.get(node, []):
            if dep not in seen:
                seen.add(dep)
                order.append(dep)
                stack.append(dep)
    return order

def main():
    parser = argparse.ArgumentParser(
        description='Compute transitive closure of Make prerequisites (excluding *-setup) for one or more targets.'
    )
    parser.add_argument(
        '-v', '--verbose', dest='verbose',
        help='WARNING: This option is not meant to be used when calling the script from another script.'
             'Specifies which package requires which dependencies', action='store_true'
    )
    parser.add_argument(
        '-f', '--file', dest='makefile',
        help='Makefile to parse', default=None
    )
    parser.add_argument(
        'targets', metavar='TARGET', nargs='+',
        help='One or more Make targets to analyze'
    )
    args = parser.parse_args()

    make_db = dump_make_database(args.makefile)
    rules = parse_rules(make_db)

    # for tgt in args.targets:
    #     closure = compute_closure(rules, tgt)
    #     if args.verbose:
    #         print(f"Dependencies for target '{tgt}':")
    #     if closure:
    #         indent = "  " if args.verbose else ""
    #         for dep in closure:
    #             print(indent + f"{dep}")
    #     elif args.verbose:
    #         print("  (none or target undefined)")
    #         print()

    if args.verbose:
        for tgt in args.targets:
            closure = compute_closure(rules, tgt)
            print(f"Dependencies for target '{tgt}':")
            if closure:
                for dep in closure:
                    print(f"  {dep}")
            else:
                print("  (none or target undefined)")
            print()
    else:
        deps_list = []
        for tgt in args.targets:
            closure = compute_closure(rules, tgt)
            if closure:
                for dep in closure:
                    deps_list.append(dep)
        deps_set = set(deps_list)
        print(*deps_set)


if __name__ == '__main__':
    main()
