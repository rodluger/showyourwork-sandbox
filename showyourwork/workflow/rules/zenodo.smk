import os
from pathlib import Path


# Get repo name
repo = "/".join(get_repo_url().split("/")[-2:])


# Are we on GitHub Actions?
ON_GITHUB_ACTIONS = os.getenv("CI", "false") == "true"


# Loop over figures
for fig in figure_dependencies:

    # Loop over dependencies for this figure
    for dep in figure_dependencies[fig]:


        # Get the dependency name and any instructions on how to generate it
        if type(dep) is OrderedDict:
            dep_name = list(dep)[0]
            if dep[dep_name] is None:
                continue
            dep_props = dict(dep[dep_name])
        elif type(figure_dependencies[fig]) is dict:
            dep_name = dep
            dep_props = figure_dependencies[fig][dep]
        else:
            continue


        # User settings
        generate = dep_props.get("generate", None)
        upload = dep_props.get("upload", None)
        file_name = str(Path(dep_name).name)
        file_path = str(Path("src/figures") / Path(dep_name).parent)
        sandbox = dep_props.get("upload", {}).get("sandbox", False)
        token_name = dep_props.get("upload", {}).get("token_name", "ZENODO_TOKEN")
        deposit_title = dep_props.get("upload", {}).get("title", f"{repo}:{dep_name}")
        deposit_description = dep_props.get("upload", {}).get("description", f"File uploaded from {repo}.")
        if upload and not generate:
            raise ValueError("Can only upload datasets when `generate` is True.")


        # Now either download the dataset (on GH Actions) or generate & upload it (locally)
        if ON_GITHUB_ACTIONS:

            rule:
                message:
                    f"Downloading dependency file {dep_name} from Zenodo..."
                output:
                    report(f"src/figures/{dep_name}", category="Dataset")
                conda:
                    POSIX(USER / "environment.yml")
                params:
                    action="download",
                    file_name=file_name,
                    file_path=file_path,
                    deposit_title=deposit_title,
                    sandbox=sandbox,
                    token_name=token_name
                script:
                    "../scripts/zenodo.py"

        elif generate:

            rule:
                message:
                    f"Generating figure dependency file {dep_name}..."
                output:
                    report(f"src/figures/{dep_name}", category="Dataset")
                conda:
                    POSIX(USER / "environment.yml")
                shell:
                    f"cd src/figures && {generate}"

            rule:
                message:
                    f"Uploading dependency file {dep_name} to Zenodo..."
                input:
                    f"src/figures/{dep_name}"
                output:
                    touch(temp(f"src/figures/{dep_name}.zenodo"))
                conda:
                    POSIX(USER / "environment.yml")
                params:
                    action="upload",
                    file_name=file_name,
                    file_path=file_path,
                    deposit_title=deposit_title,
                    deposit_description=deposit_description,
                    sandbox=sandbox,
                    token_name=token_name,
                    generate=generate,
                    repo_url="{}/tree/{}".format(get_repo_url(), get_repo_sha())
                script:
                    "../scripts/zenodo.py"

            # Make the upload a dependency of the figure
            figure_dependencies[fig].append(f"{dep_name}.zenodo")