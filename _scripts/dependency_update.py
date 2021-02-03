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

def update_dependencies(index, requirements, url):
    for dependency in requirements["dependencies"]:
        entries = index["entries"][dependency["name"]]
        entries.sort(key=lambda x: x["created"])
        dependency["version"] = entries[-1]["version"]
        dependency["repository"] = url

if __name__ == "__main__":
    index = load_index(sys.argv[1] + "/index.yaml")
    requirements = load_requirements(sys.argv[2])
    update_dependencies(index, requirements, sys.argv[1])
    dump_requirements(sys.argv[2], requirements)

