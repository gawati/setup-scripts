from __future__ import with_statement
import os, sys
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


class Configs:
    """
    The base class for configs
    """

    config_path = None

    def __init__(self):
        print blue("Reading ini file in %s" % self.config_path)

        if (os.access(self.config_path, os.R_OK) is not True):
            print red("Unable to read ini file %s, possibly no permissions or does not exist" % self.config_path)
            sys.exit()
         
        self.gcr = GawatiConfigReader(self.config_path)

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
        return dict(self.gcr.config.items(section_name))




class BuildConfigs(Configs):
    """
    Loads the build configuration ini file from the command line e.g.:
        
        fab -H localhost --set build-ini=/home/user/build.ini

    If no parameter is specified, looks for a ini file called 'build.ini' in the 
    ./ini folder        
    """
    config_path = env["build-ini"] if "build-ini" in env else '../ini/build.ini'



class GawatiConfigs(Configs):
    """
    Loads the system setup configuration ini file from the command line e.g.:
        
        fab -H localhost --set setup-ini=/home/user/dev.ini

    If no parameter is specified, looks for a ini file called 'dev.ini' in the 
    /root folder.
    To set setup-ini and build-ini together:

        fab -H localhost --set setup-ini=/home/user/dev.ini,build-ini=/home/user/build.ini

    """        

    config_path = env['setup-ini'] if "setup-ini" in env else '/root/dev.ini'




class GitHubSource:
    """
    Supports interactions with the source checked out from github
    """

    def __init__(self):
        self.build_cfg = BuildConfigs()    

    def checkout(self):
        """
        Checkout from github
        """    
        # checkout source code
        # build it 
        # upload to server
        repos = self.build_cfg.get_section("git_repos")
        src_path = self.build_cfg.source_path()
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
        repos = self.build_cfg.get_section("git_repos")
        with cd(self.build_cfg.source_path()):
            for folder_name, v in repos.iteritems():
                print blue(" building %s" % folder_name)
                with cd(folder_name):
                    run("ant xar")
        

class ExistServer:

    """
    Provides methods to access the eXist server.
    
    Run XQuerys as naked XQueries (passed as a string)
    or
    Run XQuery statements listed in a file. 

    Configuration is picked up from dev.ini, example section is provided below:
    
    
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

        self.setup_cfg = GawatiConfigs()    
        self.exist_cfg = self.setup_cfg.get_section(exist_service)
        # this returns the full home directory of the user
        self.exist_user_home = run("echo ~%s" % self.exist_cfg["user"]) ##was## "/home/%s" % self.exist_cfg["user"]
        """
        If the instance folder starts with ~ replace it with the user home for eXist user
        Otherwise return the folder itself
        """
        def instance_folder():
            instance_folder = self.exist_cfg["instanceFolder"]
            if (instance_folder.startswith("~")):
                return os.path.join(self.exist_user_home, instance_folder.replace("~/", ""))
            else:
                return instance_folder 

        """
        expand the instance folder, i.e. expand ~ to full path
        """
        self.exist_folder = instance_folder()
        self.exist_autodeploy = os.path.join(self.exist_folder, "autodeploy")
        print blue("Full path to eXist %s " % self.exist_folder)
    

    def server_uri(self):
        """
        xmldb:exist://localhost:10083/exist/xmlrpc    
        """
        return "xmldb:exist://%s:%s/exist/xmlrpc" % ('localhost', str(self.exist_cfg['port']))


   
    def execute_query(
        self, 
        xquery, 
        user, 
        passw
        ):
        """
        Runs the input XQuery commands on the server
        """
        run_map = {}
        run_map["folder"] = self.exist_folder
        run_map["server_uri"] = self.server_uri()
        run_map["user"] =  user
        run_map["password"] = passw
        run_map["xquery"] = xquery
        run_cmd = self._execute_query_tmpl(run_map)
        with hide('running', 'stdout', 'stderr'):        
            return run(run_cmd)



    def execute_file(
        self, 
        xquery_file, 
        user, 
        passw
        ):
        """
        Runs the input XQuery script file on the server
        """
        run_map = {}
        run_map["folder"] = self.exist_folder
        run_map["server_uri"] = self.server_uri()
        run_map["user"] =  user
        run_map["password"] = passw
        run_map["xquery_file"] = xquery_file
        run_cmd = self._execute_file_tmpl(run_map)
        with hide('running', 'stdout', 'stderr'):        
            return run(run_cmd)


    def _execute_query_tmpl(self, tmpl_dict):
        run_tmpl = (
           'cd %(folder)s && bin/client.sh ', 
            '-ouri=%(server_uri)s ', 
            '-u %(user)s -P %(password)s ',
            '-x  "%(xquery)s" '
        )
        return ''.join(run_tmpl) % tmpl_dict
  
    def _execute_file_tmpl(self, tmpl_dict):
        run_tmpl = (
           'cd %(folder)s && bin/client.sh ', 
            '-ouri=%(server_uri)s ', 
            '-u %(user)s -P %(password)s ',
            '-F  "%(xquery_file)s" '
        )
        return ''.join(run_tmpl) % tmpl_dict
    
    def clean_autodeploy_for_pkg(self, xar_pkg_file_name, force=True):
        xar_prefix = xar_pkg_file_name.split("-")[0]
        xar_path_adeploy = os.path.join(self.exist_autodeploy, xar_pkg_file_name)
        if (
            os.path.isfile(
                xar_path_adeploy
            )
        ):
            """
            File already exists
            """
            if (force):
                print blue("Cleaning up auto-deploy folder ")
                """
                If it exists delete it,
                remove all other related files
                """
                os.remove(xar_path_adeploy)
                from glob import glob
                for xar_del in glob(
                        os.path.join(
                            self.exist_autodeploy, 
                            xar_prefix + "*.xar"
                        )
                ):
                    os.remove(xar_del)
            else:
                print blue("Ignore cleanup of autodepoly folder")
        else:
            print green("Nothing to cleanup")

    
    def deploy_xar(self, xar_path):
        """
        Deploy XAR file
        """
        import shutil
        print blue("Deploy XAR: copying %s to %s" % (xar_path, self.exist_autodeploy))
        shutil.copy2(xar_path, self.exist_autodeploy)
                                

class XarPackage:
    """
    This class works with eXist XAR Packages
    """
    
    def __init__(self, service):
        """ 
        :param service: service is the name of the eXist service 
        """
        self.build_cfg = BuildConfigs()
        self.exist_service = service
        self.exist_server = ExistServer(service)

    def remove(self, xar_name, exist_user, exist_pw):
        """
        Uninstalls a package from the server. The full package identifier has to be provided
        Package is undeployed and removed from the repository
        
        :param xar_name: identifier of the xar package to be removed
        :param exist_user: typically the admin user in eXist
        :param exist_pw: the password of the exist_user
        """
        tmpl = Templates(self.build_cfg)
        new_file = tmpl.new_file("xql", "uninstall_app.xqlt", {"app_name": xar_name})
        print blue("Uninstalling %s on the server" % xar_name)        
        std_out = self.exist_server.execute_file(new_file, exist_user, exist_pw)         
        return std_out

    def is_valid(self, xar_path):
        """
        Check if the XAR package is a valid file
        """
        import zipfile
        xar_file = zipfile.ZipFile(xar_path)
        file_name = os.path.basename(xar_path)
        test = xar_file.testzip()
        if (test is not None):
            print red("The xar file %s is corrupt" % file_name)
            return "file-corrupt"
        else:
            return "file-valid"
        

    def deploy(self, xar_path):
        """
        deploys the xar package onto the eXist server
        """
        xar_file_name = os.path.basename(xar_path)
        xar_valid = self.is_valid(xar_path)
        if (xar_valid):
            print "%s is a valid xar package" % xar_file_name
            self.exist_server.clean_autodeploy_for_pkg(xar_file_name)
            self.exist_server.deploy_xar(xar_path)
            daemon = Daemon()
            daemon.restart(self.exist_service)
            return "deployed"
        else:
            print red("%s package cannot be deployed as the file is not valid" % xar_file_name)
            return "invalid-file"
       
         

class Templates:
    """
    This module applies string and dictionary parameter templates
    to generate configuation and code files. For example, the uninstall_app.xqlt template
    is XQuery code to remove a package from eXist. the Parameter that is applied in to 
    generate an executable code file is the package name
    """

    templates = ["xql"]
    templates_folder_name = "templates"
    runtime_folder_name = "runtime"

    def __init__(self, build_cfg):
        self.build_cfg = build_cfg
        self.template_folder = os.path.join(
            self.build_cfg.fab_path(), 
            self.templates_folder_name
        )
        self.runtime_folder = os.path.join(
            self.build_cfg.fab_path(),
            self.runtime_folder_name
        )
        print blue(" Template folder set to : %s" % self.template_folder)
        print blue(" Runtime folder set to : %s" % self.runtime_folder)

    def template(
        self, 
        template_type, 
        template_file, 
        template_map
        ):
        """
        This function uses the template, applies the template map and generates the complete file content, returns a string

        :param template_type: is the type of template, always the name of the sub-folder within templates
        :param template_file: the name of the template file. Recommended to have a suffix extension of 4 letters. e.g. "xqlt"
        :param template_map: the substitution map
        """
        ftmpl = open(
            os.path.join(self.template_folder, template_type, template_file )
        )
        fcontents = ftmpl.read()
        return fcontents % template_map
  

    def name_from_template(self, file_name):
        """
        Returns the prefix of the file name
        """
        from posixpath import basename
        return os.path.splitext(basename(file_name))[0]

    
    def new_file(
        self,
        template_type,
        template_file,
        template_map
        ):
        """
        Generates a template and writes it to the runtime folder

        :param template_type: the type of the template. Corresponds to the
               folder name of the type. e.g. "xql" and also the extension of the
               runtime. e.g. "xql" template type generates .xql files. 
        :param template_file: the name of the template file to be used
        :param template_map: the dictionary containing parameters to be set on the 
               template
        """
        contents = self.template(template_type, template_file, template_map)
        new_file = self.name_from_template(template_file) + "." + template_type
        print blue("new file from template going to be created %s" % new_file)
        path_to_new_file = os.path.join(self.runtime_folder, new_file)
        fnewfile = open(path_to_new_file, "w")
        fnewfile.write(contents)
        fnewfile.close()
        return path_to_new_file


class Daemon:

    """
    Supports starting and stopping services from within fabric
    Additionally service status can be queried via systemctl
    """

    def __init__(self):

        self.setup_cfg = GawatiConfigs()

        def sections_which_are_daemons():
            """
            Sections which are type = install are considered to be 
            daemon sections 
            """
            sections = self.setup_cfg.gcr.config.sections()
            daemon_sections = []
            for section in sections:
                if (self.setup_cfg.gcr.config.has_option(section, "type")):
                    type_val = self.setup_cfg.gcr.config.get(section, "type") 
                    if (type_val == "install"):
                        daemon_sections.append(section)
            return daemon_sections
        
        """ 
        Get daemon service names
        """
        self.daemons = sections_which_are_daemons()

        
    def start(self, service):
        """
        Start the input service
        """                
        if (service in self.daemons):
            run("systemctl start %s" % service)
        else:
            self._service_not_found_error(service)

    def stop(self, service):
        """
        Stop the input service
        """
        if (service in self.daemons):
            run("systemctl stop %s" % service)
        else:
            self._service_not_found_error(service)


    def restart(self, service):
        """
        Restart the input service
        """
        if (service in self.daemons):
            run("systemctl restart %s" % service)
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
        

