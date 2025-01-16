## Bosca Ceoil: The Blue Album — Documentation

This folder contains source files for the online documentation for **Bosca Ceoil: The Blue Album**. The purpose of this documentation is to provide access to learning and reference materials related to _Bosca Ceoil_ at a permanent online location. You can find this documentation hosted at:

- https://humnom.net/apps/boscaceoil/docs/

All contributions that improve the quality and presentation of the content of this documentation are welcome! Read on to learn how to contribute.


### Contributing content and articles

If you have found a typo in one of the articles or think there is content missing from this documentation, please feel free to open a pull request that addresses the issue.

The aim is to document every bit of functionality offered by _Bosca Ceoil Blue_, as well as to provide tips and tricks that can help beginners master making music with this app. We also welcome links to external tutorials, video or written, that explain how _Bosca_ works and guide you through its tools.

You can find the contents of this documentation in the `/src` folder. Each page is stored as a Markdown file with a metadata header at the top. These files are then converted into HTML using the [documentation build system](#building-and-testing).

#### Writing guidelines

Here are some general recommendations for writing content:

- Write only in English; but feel free to reference guides in other languages with a clear marking.
- Usage of a formal style is preferred, but there is no need to be dry and stern.
- Consider how your text looks on the page; break up long sentences and paragraphs, and use emphasis formatting tactically.
- Always assume the reader is not very familiar with the specific domain jargon.

#### Creating and modifying articles

To start editing, just open the `.md` file for the page that you want to contribute to and make the changes. All parts of the standard Markdown syntax are at your disposal.

If you want to insert an image, add it to the `/assets/images` folder first and then reference it in the document. When referencing images, or other articles, assume that the content in `/src` and `/assets` is in the root folder.

So if your image is at `/assets/images/bosca-is-awesome.png`, use

```md
![](images/bosca-is-awesome.png)
```

And if the article that you want to link is at `/src/another-article.md`, use

```md
Read in [another article](another-article.md)
``` 

If you want to add a new article, place and `.md` file in the `/src` folder. Use the root of the `/src` folder for top-level articles (the ones that go into the sidebar navigation). Put other articles into subfolders according to their topic (you can create a new one if necessary).

When adding new top-level articles, make sure to add them to the `build.py` file to ensure the order of articles in the navigation sidebar. Look for the `TOP_LEVEL_PAGES` variable at the top of the file for an example on how to do that.

#### Metadata header

The metadata header is important to help create HTML files for the documentation.

The header goes at the top and must be put in between two `---` lines. No empty lines are allowed in the header. Each metadata field consists of a key and a value separated by a colon (`:`). The value can be empty.

Each document must have at least some metadata defined. These fields are mandatory:

```
---
title: Notes and Patterns
---
```

And these are optional and should only be used when necessary:

```
---
template: article
description: Documentation for Bosca Ceoil Blue.
keywords: bosca ceoil blue, music, sequencer, documentation
---
```


### Contributing to the website

The documentation consists of static HTML files generated from the source Markdown files.

- Files in the `/src` folder define pages and their unique content, as well as some metadata used when rendering HTML.
- Each page uses one of the templates located in `/templates`, with `article.html` being the default one.
- Other static files which can be used by the documentation pages are located in `/assets` and copied as is to the output folder by the [documentation build system](#building-and-testing).

Templates are written as normal HTML files with strings delimited with `%` used as placeholders for inserted content. Currently, these placeholders are used:

- `%BOSCA_VERSION%`, the version of Bosca this documentation is for.
- `%PAGE_TITLE%`, the title of the page.
- `%PAGE_DESCRIPTION%`, the SEO-friendly description of the page.
- `%PAGE_KEYWORDS%`, SEO-friendly keywords for the page.
- `%PAGE_CONTENT%`, rendered page content as HTML.
- `%PAGE_NAVIGATION%`, rendered navigation entries as HTML.

The main styling configuration is defined in `/assets/styles/theme.css`. Both light and dark modes are supported and must be accounted for. Make sure to use CSS variables to colors and other shared values.


### Building and testing

Whether you want to test your edits to one of the articles, or validate changes to the layout and styles, you probably want to build the HTML locally.

This documentation is built using Python. You also need to be familiar with the command line interface to successfully build the website.

#### Python virtual environment

It's recommended to use a virtual environment before installing dependencies. To create a virtual environment, first make sure you're in the `/docs` folder of this repository (the same folder where this readme is located). Then run

```sh
python -m venv ./.venv
```

Next, activate it. On Linux and macOS you can use `source`:

```sh
source ./.venv/bin/activate
```

And on Windows, you can use this Powershell script directly:

```powershell
.\.venv\Scripts\Activate.ps1
```

Note that you might need to allow remotely signed Powershell scripts to be able to run it. This can be done with the following command:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Now you should be able to safely work with Python in an isolated, virtual environment.

#### Dependencies

This project depends on the [`python-markdown`](https://github.com/Python-Markdown/markdown) library. This and any other necessary dependencies are listed in `requirements.txt`. You can install everything using the following command:

```sh
pip install -r requirements.txt
```

If you want to add another dependency to the project, make sure to list it with a pinned version in the same file.

#### Building and running

To build the project, execute the following:

```sh
python ./build.py
```

If you want to contribute to the build system, the `build.py` file contains the entire workflow and is fairly well documented. Please follow the code style established by existing code when making changes.

Once the build is complete, all resources necessary for the project to run can be found in the `/out` folder. You can create a local web server with Python to view the results:

```sh
python -m http.server -d ./out 8080
```

You can now open your browser and navigate to [localhost:8080](http://localhost:8080).
