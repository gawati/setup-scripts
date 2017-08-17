from fabric.api import run
import gawati
"""
This module is the entry point to all fabric actions.
You can run:
    
    ./fab -H localhost --list
 
To see a list of available actions.

Actions can be run across multiple hosts: 

    ./fab -H localhost,anotherhost <action-name>

If you are always running actions on localhost, there is a short-form:

    ./fl <action-name>

Actions can take parameters:

    ./fl start:eXist-st

Here eXist-st is the parameter to the start action.

You can pass multiple parameters by separating them with a comma.

Actions need to be run with sudo:

    sudo ./fl <action-name>

as configuration information is read from dev.ini which is in the root home
folder (typically).
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
    

def deploy_exist_modules(service):
    """
    Deploys all built eXist modules from  ./src
    
    :param service: name of the eXist service as specified in dev.ini.  
    """
    ed = gawati.ExistService(service)
    up = _prompt_user_pass()
    ed.run_on_server("repo:list()", up["user"], up["password"])
    ##  print ed.exist_folder()    
    


def start(service):
    """
    Starts the specified services

    :param service: name of the eXist service as specified in dev.ini.  
    """
    daemon = gawati.Daemon()
    daemon.start(service)

def stop(service):
    """
    Stops the specified service

    :param service: name of the eXist service as specified in dev.ini.  
    """
    daemon = gawati.Daemon()
    daemon.stop(service)


def remove_xar(
    service, 
    xar_name, 
    debug=False
    ):
    """
    Uninstalls the XAR package from the eXist server

    :param service: name of the eXist service as specified in dev.ini.  
    :param xar_name: full identifier of the xar package to remove 
                    e.g. http://exist-db.org/apps/preconferece-2017
    :param debug: shows every command in stdout when true, this may not be desirable
                  under normal circumstances since it can echo passwords
    """

    xar = gawati.XarPackage(service)
    up = _prompt_user_pass()
    out = xar.remove(xar_name, up["user"], up["password"])
    outputs = out.split("\r\n")
    json_out = {"remove_xar": outputs[-1] if (debug == False) else outputs }
    import json
    print json.dumps(json_out)
    return json_out


def install_xar(
    service,
    xar_path,
    hot_deploy=False,
    debug=False
    ):
    """
    Uninstalls the XAR package from the eXist server

    :param service: name of the eXist service as specified in dev.ini.  
    :param xar_path: full file system path to the xar package to install
    :param hot_deploy: set to true, does a hot deployment without restarting the server
                    (not implemented at the moment)
    :param debug: shows every command in stdout when true, this may not be desirable
                  under normal circumstances since it can echo passwords
    """

    xar = gawati.XarPackage(service)
    if (hot_deploy):
        print "Hot deployment is not implemented yet!"
        return json.dumps({"install_xar": "not-implemented"})
    else:
        out = xar.deploy(xar_path)
        json_out = {"install_xar": out}
        import json
        print json.dumps(json_out)
        return json_out
    
def _prompt_user_pass():
    from getpass import getpass
    _user = getpass("Enter user name:")
    _pass = getpass("Enter password:")
    return {'user': _user, 'password': _pass}
