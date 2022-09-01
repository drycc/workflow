import sys
import yaml
import requests
from contextlib import closing


def load_index(url):
    with closing(requests.get(url)) as response:
        return yaml.load(response.text, Loader=yaml.Loader)

def load_requirements(requirements_file):
    with open(requirements_file) as f:
        return yaml.load(f, Loader=yaml.Loader)

def dump_requirements(requirements_file, requirements):
    with open(requirements_file, "w") as f:
        return yaml.dump(requirements, stream=f, Dumper=yaml.Dumper)

def update_dependencies(requirements, url):
    for dependency in requirements["dependencies"]:
        dependency["repository"] = url

if __name__ == "__main__":
    requirements = load_requirements(sys.argv[2])
    update_dependencies(requirements, sys.argv[1])
    dump_requirements(sys.argv[2], requirements)

