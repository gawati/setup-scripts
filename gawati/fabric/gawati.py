from __future__ import with_statement
import os
from fabric import state
from fabric.api import *
from fabric.colors import red, green, blue
from fabric.contrib.files import exists
from ConfigParser import SafeConfigParser

"""

This module has the core functionality used by the fabric deployment
scripts of Gawati

"""


class GawatiConfigReader:
    """
    Reads the input ini file for the installation
    """

    def __init__(self, inifile):
        self.config = SafeConfigParser()
        self.config.optionxform = str
        self.config.read(inifile)




class GawatiConfigs:
    """
    Loads the configuration ini file from the command line e.g.:
        
        fab -H localhost --ini /home/user/dev.ini

    If no parameter is specified, looks for a ini file called 'dev.ini' in the 
    /root folder        

    """        

    config_path = env.ini if "ini" in env else '/root/dev.ini'

    def __init__(self):
        print blue("Reading ini file in %s" % self.config_path)
        self.gwconfig = GawatiConfigReader(self.config_path)

    def fab_path(self):
        """
        Returns the parent path of the currently running fabric file
        """

        return os.path.abspath(os.path.join(env.real_fabfile, ".."))

    def source_path(self):
        """
        Returns the path to the 'src' folder that contains code checked out from github
        """

        fab_path = self.fab_path()
        return os.path.join(fab_path, "..", "src")

    
                
    def get_section(self, section_name):
        """
        Returns the items of the specified section name in the input ini file.
        """
        return dict(self.gwconfig.config.items(section_name))


    def get_config(self, section_name, config_name, raw=False):
        """
        Gets a parameter value for a parameter from a section

        :param section_name: The name of the section in the ini file
        :param config_name: The name of the parameter in the section
        :param raw: Setting the raw parameter gets the raw - non-interpolated value
        
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
    """
    Supports interactions with the source checked out from github
    """

    def __init__(self):
        self.cfgs = GawatiConfigs()    

    def checkout(self):
        """
        Checkout from github
        """    
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
        """
        Build project
        """        

        # any preprocess to be done here
        repos = self.cfgs.get_section("git_repos")
        with cd(self.cfgs.source_path()):
            for folder_name, v in repos.iteritems():
                print blue(" building %s" % folder_name)
                with cd(folder_name):
                    run("ant xar")
        

class ExistDeploy:

    """
    [eXist-st]
    type=install
    installer=existdb
    version=3.4.0
    user=xstst
    instanceFolder=~/apps/existdb
    dataFolder=~/apps/existdata
    port=10083
    sslport=10443
    options=daemon

    """        

    def __init__(self, exist_service):

        self.cfgs = GawatiConfigs()    
        self.exist_cfg = self.cfgs.get_section(exist_service)
        self.exist_user_home = "/home/%s" % self.exist_cfg["user"]
        instance_folder = self.exist_cfg["instanceFolder"]

        def full_path_to_exist():
                        
            if (instance_folder.startswith("~")):
                return self.exist_user_home + instance_folder.replace("~", "")
            else:
                return instance_folder
        
        self.exist_folder = full_path_to_exist()
        print blue("Full path to eXist %s " % self.exist_folder)
    
    def exist_folder(self):
        return self.exist_folder            

    def server_uri(self):
        """
        xmldb:exist://localhost:10083/exist/xmlrpc    
        """
        return "xmldb:exist://%s:%s/exist/xmlrpc" % ('localhost', str(self.exist_cfg['port']))


    def run_on_server(self, xquery, user, passw):
        run_map = {}
        run_map["folder"] = self.exist_folder
        run_map["server_uri"] = self.server_uri()
        run_map["user"] =  user
        run_map["password"] = passw
        run_map["xquery"] = xquery
        run_cmd = self._run_on_server_tmpl(run_map)
        with hide('running', 'stdout'):        
            run(run_cmd)


    def _run_on_server_tmpl(self, tmpl_dict):
        return 'cd %(folder)s && bin/client.sh -ouri=%(server_uri)s -u %(user)s -P %(password)s -x  "%(xquery)s" ' % tmpl_dict
  
      

class Daemon:

    """
    Supports starting and stopping services from within fabric
    Additionally service status can be queried via systemctl
    """

    daemons = ["httpd", "eXist-st", "eXist-be", "jetty-dev01"]
    
    def __init__(self):
        self.cfgs = GawatiConfigs()

        
    def start(self, service):
        """
        Start the input service
        """                

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
        """
        Stop the input service
        """

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
        """
        Checks the current status of the service, if its running or not
        """

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
        

