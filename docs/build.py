###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# Main docs builder script.

from pathlib import Path
from os import walk
import shutil

import markdown
from colorize import magenta, cyan, yellow, green, gray, bold

# Paths.
DOCS_SOURCE = "./src"
DOCS_OUT = "./out"
DOCS_TEMPLATES = "./templates"
DOCS_ASSETS = "./assets"

# Templates.
PAGE_DEFAULTS = {
    "BOSCA_VERSION": "3.1",
    "PAGE_TITLE": "Bosca Ceoil: The Blue Album — Documentation",
    "PAGE_DESCRIPTION": "Documentation for Bosca Ceoil Blue, a beginner-friendly music making app.",
    "PAGE_KEYWORDS": "bosca ceoil, bosca ceoil blue, music, sequencer, synthesizer, chiptune, documentation",
    "PAGE_CONTENT": "",
}
PAGE_TEMPLATES = {}
DEFAULT_PAGE_TEMPLATE = "article"

# Navigation.
# Add page names here to force the order. Top-level pages not on
# this list are appended to the end.
TOP_LEVEL_PAGES = {
    "index": {},
    "overview": {},
    "notes_and_patterns": {},
    "arrangements": {},
    "instruments": {},
    "export_import": {},
    "shortcuts": {},
    "community": {},
}
ALL_PAGES = []

# Instance of the markdown builder. We enabled several extensions by default:
# - The meta extension allows to extract frontmatter-like metadata.
# - The tables extension enables syntax for tables.
# - The toc extension adds support for a table of content, and gives headings unique ids.
builder = markdown.Markdown(extensions=['meta', 'tables', 'toc'])


# Helpers.

def get_template(key, fallback = True):
    # Check the cache first.
    if key in PAGE_TEMPLATES:
        return PAGE_TEMPLATES[key]
    
    # If not in cache, try to find the file.
    template_path = Path(DOCS_TEMPLATES, f"{key}.html")
    if not template_path.exists():
        # If the file doesn't exist, try the default template.
        if fallback:
            return get_template(DEFAULT_PAGE_TEMPLATE, False)
        # If even the default template doesn't exist, that's bad.
        raise ValueError(f"Invalid template key '{key}'")
    
    # Read the template contents.
    template = ""
    with open(template_path, mode="r", encoding="utf-8") as f:
        template = f.read()
    
    # Store it in cache and return.
    PAGE_TEMPLATES[key] = template
    return template


def convert_source(inpath, outpath, toplevel = False):
    html = ""
    meta = {}
    
    print(f"{gray('Rendering page')} {yellow(inpath)} {gray('to')} {cyan(outpath)}")
    
    # Read the source file, convert it to HTML, and extract metadata.
    with open(inpath, mode="r", encoding="utf-8") as f:
        text = f.read()
        builder.reset()
        html = builder.convert(text)
        meta = builder.Meta
    
    # Retrieve the template used by this page.
    template_key = DEFAULT_PAGE_TEMPLATE
    if "template" in meta and len(meta["template"]) > 0:
        template_key = meta["template"][0]
    template = get_template(template_key)
    
    # Prepare values for template placeholders.
    
    template_values = PAGE_DEFAULTS.copy()
    template_values["PAGE_CONTENT"] = html
    
    if "title" in meta and len(meta["title"]) > 0:
        value = meta["title"][0]
        template_values["PAGE_TITLE"] = f"{value} — Bosca Ceoil: The Blue Album — Documentation"
    
    if "description" in meta and len(meta["description"]) > 0:
        template_values["PAGE_DESCRIPTION"] = meta["description"][0]
    
    if "keywords" in meta and len(meta["keywords"]) > 0:
        template_values["PAGE_KEYWORDS"] = meta["keywords"][0]
    
    # Complete the page by replacing placeholder in the template.
    for key in template_values:
        value = template_values[key]
        template = template.replace(f"%{key}%", value)
    
    # Write the output.
    with open(outpath, mode="w", encoding="utf-8") as f:
        f.write(template)
        ALL_PAGES.append(outpath)
        
        # Add top-level pages to the navigation list. But only if it has a title.
        if toplevel and "title" in meta and len(meta["title"]) > 0:
            toplevel_key = outpath.name[:-len(outpath.suffix)]
            TOP_LEVEL_PAGES[toplevel_key] = {
                "outpath": outpath,
                "title": meta["title"][0],
            }


def create_navigation(current_path):
    text = ""
    # Normalize the DOCS_OUT variable before calculating its length.
    outdir_len = len(str(Path(DOCS_OUT)))
    
    for toplevel_key in TOP_LEVEL_PAGES:
        data = TOP_LEVEL_PAGES[toplevel_key]
        # Normalize the outpath and remove output path prefix.
        url = str(data["outpath"])[outdir_len:].replace("\\", "/")
        title = data["title"]
        
        if current_path == data["outpath"]:
            text += f'<a href="{url}" class="navigation-item active">{title}</a>\n'
        else:
            text += f'<a href="{url}" class="navigation-item">{title}</a>\n'
    
    return text


# Build routine.

def build():
    print(bold(magenta("Starting Bosca Ceoil Blue documentation build")))
    print("")

    # Clear the output folder first.
    print(gray("Clearing previous output"))
    shutil.rmtree(DOCS_OUT, ignore_errors=True)

    print("")
    print(bold("Rendering pages..."))

    # Iterate over all source files, recursively, and convert them.
    for (dirpath, dirnames, filenames) in walk(DOCS_SOURCE):
        toplevel = (dirpath == DOCS_SOURCE)
        
        out_dirpath = Path(DOCS_OUT, dirpath[len(DOCS_SOURCE) + 1:])
        # Ensure that the output folder exists.
        out_dirpath.mkdir(parents=True, exist_ok=True)
        
        # For every Markdown file in the folder, perform the conversion.
        for filename in filenames:
            if not filename.endswith(".md"):
                continue
            
            filepath = Path(dirpath, filename)
            out_filepath = out_dirpath.joinpath(f"{filename[:-3]}.html")
            convert_source(filepath, out_filepath, toplevel)

    print("")
    print(bold("Creating navigation..."))

    # Update generated HTML files with the navigation.
    for outpath in ALL_PAGES:
        with open(outpath, "r+") as f:
            print(f"{gray('Creating navigation on page')} {cyan(outpath)}")
            
            text = f.read()
            f.seek(0)
            f.truncate()
            
            # Generate custom navigation for each page to highlight active page.
            navigation = create_navigation(outpath)
            text = text.replace(f"%PAGE_NAVIGATION%", navigation)
            f.write(text)

    print("")
    print(bold("Copying assets..."))

    # Copy the assets to the output.
    for (dirpath, dirnames, filenames) in walk(DOCS_ASSETS):
        out_dirpath = Path(DOCS_OUT, dirpath[len(DOCS_ASSETS) + 1:])
        # Ensure that the output folder exists.
        out_dirpath.mkdir(parents=True, exist_ok=True)
        
        # For every Markdown file in the folder, perform the conversion.
        for filename in filenames:
            filepath = Path(dirpath, filename)
            out_filepath = out_dirpath.joinpath(filename)
            
            print(f"{gray('Copying asset')} {yellow(filepath)} {gray('to')} {cyan(out_filepath)}")
            shutil.copyfile(filepath, out_filepath)

    print("")
    print(bold(green("Done!")))
    print("")


# Run it.
build()
