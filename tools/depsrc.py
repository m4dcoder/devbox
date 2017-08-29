import argparse
import json
import pip

parser = argparse.ArgumentParser(description='Identify source of dependencies.')
parser.add_argument('dep', type=str, help='Name of the dependency.')

args = parser.parse_args()

distributions = pip.get_installed_distributions()

deps = {}

for dist in distributions:
    reqs = [req for req in dist.requires() if req.key == args.dep]

    if reqs:
        deps[dist.key] = {
            req.key: [spec[0]+spec[1] for spec in req.specs] for req in reqs
        }

if deps:
    print json.dumps(deps, indent=4, sort_keys=True)
