import json
import urllib
import urllib.request
import tarfile


TEMP = snakemake.params["TEMP"]
OS = snakemake.params["OS"]


def get_tectonic_link():
    """
    Get the download link for the latest Linux release of tectonic on GitHub.

    """
    link = None
    with urllib.request.urlopen(
        "https://api.github.com/repos/tectonic-typesetting/tectonic/releases"
    ) as url:
        data = json.loads(url.read().decode())
        for entry in data:
            if entry.get("tag_name", "") == "continuous":
                assets = entry.get("assets")
                for asset in assets:
                    if OS in asset.get("name", ""):
                        link = asset.get("browser_download_url")
                        return link


# Download the tarball
link = get_tectonic_link()
urllib.request.urlretrieve(link, "tectonic.tar.gz")


# Extract it
with tarfile.open("tectonic.tar.gz") as file:
    
    import os
    
    def is_within_directory(directory, target):
        
        abs_directory = os.path.abspath(directory)
        abs_target = os.path.abspath(target)
    
        prefix = os.path.commonprefix([abs_directory, abs_target])
        
        return prefix == abs_directory
    
    def safe_extract(tar, path=".", members=None, *, numeric_owner=False):
    
        for member in tar.getmembers():
            member_path = os.path.join(path, member.name)
            if not is_within_directory(path, member_path):
                raise Exception("Attempted Path Traversal in Tar File")
    
        tar.extractall(path, members, numeric_owner=numeric_owner) 
        
    
    safe_extract(file, TEMP)