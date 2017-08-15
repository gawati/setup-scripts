from fabric.api import run
import gawati


def checkout():
    """
    Checkout from Github
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
    # checkout source code
    # build it 
    # upload to server
    ghub = gawati.GitHubSource()
    ghub.checkout()
    ghub.build()
    ghub.deploy()


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



