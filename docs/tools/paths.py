###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2025 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

from markdown import Extension
from markdown.treeprocessors import Treeprocessor
import xml.etree.ElementTree as etree


class AbsoluteLinkProcessor(Treeprocessor):
    def __init__(self, md, config):
        super().__init__(md)
        
        self.base_path = config["base"]
    
    
    def run(self, root: etree.Element):
        self.update_links(root)
        self.update_images(root)
    
    
    def update_links(self, root: etree.Element):
        for el in root.iter("a"):
            if "href" in el.attrib and el.attrib["href"].startswith("/"):
                el.attrib["href"] = self.base_path + el.attrib["href"]
    
    
    def update_images(self, root: etree.Element):
        for el in root.iter("img"):
            if "src" in el.attrib and el.attrib["src"].startswith("/"):
                el.set("src", self.base_path + el.attrib["src"])


class MarkdownPaths(Extension):
    def __init__(self, **kwargs):
        self.config = {
            'base': [
                '', 'Base path for absolute links.'
            ],
        }
        
        super().__init__(**kwargs)
    
    
    def extendMarkdown(self, md):
        md.treeprocessors.register(AbsoluteLinkProcessor(md, self.getConfigs()), 'abslinks', 1)
