from __future__ import with_statement
import os
from fabric import state
from fabric.api import *
from fabric.colors import red, green, blue
from fabric.contrib.files import exists
from ConfigParser import SafeConfigParser


class GawatiConfigReader:

    """
    Provides access to the dev.ini build configuration file
    """

    def __init__(self, inifile):
        self.config = SafeConfigParser()
        self.config.read(inifile)




class GawatiConfigs:
    
    config_path = "/root/dev.ini"

    def __init__(self):
        self.gwconfig = GawatiConfigReader(self.config_path)

    def fab_path(self):
        """
        Returns the parent path of the currently running fabric file
        """

        return os.path.abspath(os.path.join(env.real_fabfile, ".."))

    def source_path(self):

        fab_path = self.fab_path()
        return os.path.join(fab_path, "..", "src")

    
                
    def get_section(self, section_name):
        return dict(self.gwconfig.config.items(section_name))

    def get_config(self, section_name, config_name, raw=False):
        """
        The raw parameter gets the raw - non-interpolated value
        """
        if self.gwconfig.config.has_section(section_name):
            if self.gwconfig.config.has_option(section_name, config_name):
                return self.gwconfig.config.get(
                        section_name,
                        config_name,
                        raw
                        ).strip()
            else:
                #print "warning : section [", section_name, \
                #    "] does not have option name ", config_name, " !!!!"
                return ""
        else:
            #print "warning: section [", section_name, \
            #    "] does not exist !!!"
            return ""



class GitHubSource:

    def __init__(self):
        self.cfgs = GawatiConfigs()    

    def checkout(self):
    
        # checkout source code
        # build it 
        # upload to server
        repos = self.cfgs.get_section("git_repos")
        src_path = self.cfgs.source_path()
        sudo("mkdir -p %s" % src_path)
        with cd(src_path):
            for folder_name, git_repo in repos.iteritems():
                print blue(" cloning %s" % folder_name)
                sudo("git clone %s %s" % (git_repo, folder_name))


    def build(self):

        # any preprocess to be done here
        repos = self.cfgs.get_section("git_repos")
        with cd(self.cfgs.source_path()):
            for folder_name, v in repos.iteritems():
                print blue(" building %s" % folder_name)
                with cd(folder_name):
                    sudo("ant xar")
        
    def deploy_xar(self):
        repos = self.cfgs.get_section("git_repos")
