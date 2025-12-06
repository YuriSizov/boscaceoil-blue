###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# Main docs builder script.

import argparse
from pathlib import Path
from string import Template
from os import walk
import shutil

import markdown
from tools.colorize import magenta, cyan, yellow, green, gray, bold
from tools.paths import MarkdownPaths

# Paths.
DOCS_BASE = Path(__file__).parent.resolve()
DOCS_SOURCE = DOCS_BASE / "src"
DOCS_OUT = DOCS_BASE / "out"
DOCS_TEMPLATES = DOCS_BASE / "templates"
DOCS_ASSETS = DOCS_BASE / "assets"

# Templates.
PAGE_DEFAULTS = {
    "BOSCA_VERSION": "3.1.2",
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
    "effects": {},
    "export_import": {},
    "shortcuts": {},
    "community": {},
}
ALL_PAGES = []

LINK_BASE_PATH = "http://localhost:8080"

# Command line arguments.
parser = argparse.ArgumentParser()
parser.add_argument("--release", action="store_true", help="Enables release-mode settings.")
args = parser.parse_args()

if args.release:
    LINK_BASE_PATH = "https://humnom.net/apps/boscaceoil/docs"

# Instance of the markdown builder. We enabled several extensions by default:
# - The meta extension allows to extract frontmatter-like metadata.
# - The tables extension enables syntax for tables.
# - The toc extension adds support for a table of content, and gives headings unique ids.
builder = markdown.Markdown(extensions=['meta', 'tables', 'toc', MarkdownPaths(base=LINK_BASE_PATH)])


# Helpers.

def get_template(key, fallback=True):
    # Check the cache first.
    if key in PAGE_TEMPLATES:
        return PAGE_TEMPLATES[key]
    
    # If not in cache, try to find the file.
    template_path = DOCS_TEMPLATES / f"{key}.html"
    if not template_path.exists():
        # If the file doesn't exist, try the default template.
        if fallback:
            return get_template(DEFAULT_PAGE_TEMPLATE, False)
         # If even the default template doesn't exist, that's bad.
        raise ValueError(f"Invalid template key '{key}'")
    
    # Read the template contents.
    template_str = template_path.read_text(encoding="utf-8")
    PAGE_TEMPLATES[key] = template_str
    return template_str

def convert_source(inpath, outpath, toplevel=False):
    print(f"{gray('Rendering page')} {yellow(inpath)} {gray('to')} {cyan(outpath)}")
    
    # Read the source file, convert it to HTML, and extract metadata.
    text = inpath.read_text(encoding="utf-8")
    builder.reset()
    html = builder.convert(text)
    meta = builder.Meta

    template_key = DEFAULT_PAGE_TEMPLATE
    if "template" in meta and meta["template"]:
        template_key = meta["template"][0]
    template_str = get_template(template_key)
    
    # Prepare values for template placeholders.
    
    template_values = PAGE_DEFAULTS.copy()
    template_values["PAGE_CONTENT"] = html

    if "title" in meta and meta["title"]:
        template_values["PAGE_TITLE"] = f"{meta['title'][0]} — Bosca Ceoil: The Blue Album — Documentation"
    if "description" in meta and meta["description"]:
        template_values["PAGE_DESCRIPTION"] = meta["description"][0]
    if "keywords" in meta and meta["keywords"]:
        template_values["PAGE_KEYWORDS"] = meta["keywords"][0]
    
    # Complete the page by replacing placeholder in the template.
    html_output = Template(template_str).safe_substitute(template_values)
    
    # Write the output.
    outpath.parent.mkdir(parents=True, exist_ok=True)
    outpath.write_text(html_output, encoding="utf-8")
    ALL_PAGES.append(outpath)
        
    # Add top-level pages to the navigation list. But only if it has a title
    if toplevel and "title" in meta and meta["title"]:
        toplevel_key = outpath.stem
        TOP_LEVEL_PAGES[toplevel_key] = {
            "outpath": outpath,
            "title": meta["title"][0],
        }

def create_navigation(current_path):
    text = ""
    # Normalize the DOCS_OUT variable before calculating its length.
    outdir_len = len(str(DOCS_OUT))
    
    for key, data in TOP_LEVEL_PAGES.items():
        if "outpath" not in data or "title" not in data:
            continue
        url = str(data["outpath"])[outdir_len:].replace("\\", "/")[1:]
        title = data["title"]
        
        if current_path == data["outpath"]:
            text += f'<a href="#_content" class="navigation-item active">{title}</a>\n'
        else:
            text += f'<a href="{LINK_BASE_PATH}/{url}#_content" class="navigation-item">{title}</a>\n'
    
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
    for dirpath, dirnames, filenames in walk(DOCS_SOURCE):
        toplevel = (Path(dirpath) == DOCS_SOURCE)
        
        out_dirpath = DOCS_OUT / Path(dirpath).relative_to(DOCS_SOURCE)
        # Ensure that the output folder exists.
        out_dirpath.mkdir(parents=True, exist_ok=True)
        
        # For every Markdown file in the folder, perform the conversion.
        for filename in filenames:
            if not filename.endswith(".md"):
                continue
            filepath = Path(dirpath) / filename
            out_filepath = out_dirpath / f"{filename[:-3]}.html"
            convert_source(filepath, out_filepath, toplevel)

    print("")
    print(bold("Creating navigation..."))

    # Update generated HTML files with the navigation.
    for outpath in ALL_PAGES:
        print(f"{gray('Creating navigation on page')} {cyan(outpath)}")
        text = outpath.read_text(encoding="utf-8")
            
        # Generate custom navigation for each page to highlight active page.
        navigation = create_navigation(outpath)
        html_output = Template(text).safe_substitute(PAGE_NAVIGATION=navigation)
        outpath.write_text(html_output, encoding="utf-8")

    print("")
    print(bold("Copying assets..."))

    # Copy the assets to the output.
    for dirpath, dirnames, filenames in walk(DOCS_ASSETS):
        out_dirpath = DOCS_OUT / Path(dirpath).relative_to(DOCS_ASSETS)
        # Ensure that the output folder exists.
        out_dirpath.mkdir(parents=True, exist_ok=True)
        
        # For every Markdown file in the folder, perform the conversion.
        for filename in filenames:
            filepath = Path(dirpath) / filename
            out_filepath = out_dirpath / filename
            
            print(f"{gray('Copying asset')} {yellow(filepath)} {gray('to')} {cyan(out_filepath)}")
            shutil.copyfile(filepath, out_filepath)

    print("")
    print(bold(green("Done!")))
    print("")


# Run it.
build()