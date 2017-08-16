from fabric.api import run
import gawati
"""
This module is the entry point to all fabric actions.
You can run:
    
    ./fab --list 
To see a list of available actions
"""




def checkout():
    """
    Checkout code for all configured packages from Github
    Packages are picked up in the order listed in the [git_repos] section
    """

    ghub = gawati.GitHubSource()
    ghub.checkout()

def build():
    """
    Build checked out code; expects 'checkout' to have been run 
    """

    ghub = gawati.GitHubSource()
    ghub.build()
    
def deploy():
    """
    Deploy built packages to server; expects 'build' to have been run
    """

    ghub = gawati.GitHubSource()
    ghub.deploy()
    

def source_deploy():
    """
    Does a source checkout, build and deploy
    """
    ghub = gawati.GitHubSource()
    ghub.checkout()
    ghub.build()
    ghub.deploy()

def deploy_exist_modules(service):
    """
    Deploys all built eXist modules from  ./src 
    """
    ed = gawati.ExistService(service)
    up = _prompt_user_pass()
    ed.run_on_server("repo:list()", up["user"], up["password"])
    ##  print ed.exist_folder()    
    


def start(service):
    """
    Starts the specified services
    """
    daemon = gawati.Daemon()
    daemon.start(service)

def stop(service):
    """
    Stops the specified service
    """
    daemon = gawati.Daemon()
    daemon.stop(service)


def remove_xar(service, xar_name="http://exist-db.org/apps/preconferece-2017"):
    # !+(AH, 2017-08-16) to be completed
    xar = XarPackage(service)
    up = _prompt_user_pass()
    out = xar.remove(xar_name, up["user"], up["password"])
    print "<remove_xar>%s</remove_xar>" % out

def _prompt_user_pass():
    from getpass import getpass
    _user = getpass("Enter user name:")
    _pass = getpass("Enter password:")
    return {'user': _user, 'password': _pass}
