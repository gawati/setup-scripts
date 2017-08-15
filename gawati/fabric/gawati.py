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
    
    config_path = env.ini if "ini" in env else '/root/dev.ini'

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
        run("mkdir -p %s" % src_path)
        with cd(src_path):
            for folder_name, git_repo in repos.iteritems():
                print blue(" cloning %s" % folder_name)
                run("git clone %s %s" % (git_repo, folder_name))


    def build(self):

        # any preprocess to be done here
        repos = self.cfgs.get_section("git_repos")
        with cd(self.cfgs.source_path()):
            for folder_name, v in repos.iteritems():
                print blue(" building %s" % folder_name)
                with cd(folder_name):
                    run("ant xar")
        
    def deploy_xar(self, service):
        
        # prompt for password
        
        


class Daemon:

    daemons = ["httpd", "eXist-st", "eXist-be", "jetty-dev01"]
    
    def __init__(self):
        self.cfgs = GawatiConfigs()

        
    def start(self, service):
        if (service in self.daemons):

            is_active = self._service_is_active(service)

            if (is_active == "unknown"):
                self._service_not_found_error(service)
            elif (is_active == "failed"):
                sudo("systemctl start %s" % service)
            elif (is_active == "active"):
                print red("Service %s is already running" % service)
            else:
                print red("Current service status cannot be determined, attempting to start %s" % service)
                sudo("systemctl start %s" % service)
        else:
            self._service_not_found_error(service)

    def stop(self, service):
        if (service in self.daemons):

            is_active = self._service_is_active(service)

            if (is_active == "unknown"):
                self._service_not_found_error(service)
            elif (is_active == "failed"):
                print red("Service %s is already stopped" % service)
            elif (is_active == "active"):
                sudo("systemctl stop %s" % service)
            else:
                print red("Current service status cannot be determined, attempting to stop %s" % service)
                sudo("systemctl stop %s" % service)

        else:

            self._service_not_found_error(service)

    def is_active(self, service):
        active = self._service_is_active(service)
        if (active == "failed"):
            return False
        elif (active == "active"):
            return True
        else:
            print red("Service %s status is unknown" % active)
            return False
    
    def _service_not_found_error(self, service):
        print red("Service %s not found" % service)
    
   
    def _service_is_active(self, service):
        is_active = "failed"
        with warn_only():
            is_active = run("systemctl is-active %s" % service)
        return is_active
        
