from fabric.api import run
import gawati


def host_type():
    run('uname -s')

def checkout():
    ghub = gawati.GitHubSource()
    ghub.checkout()

def build():
    ghub = gawati.GitHubSource()
    ghub.build()
    
def deploy():
    ghub = gawati.GitHubSource()
    ghub.deploy()
    

def source_deploy():
    # checkout source code
    # build it 
    # upload to server
    ghub = gawati.GitHubSource()
    ghub.checkout()
    ghub.build()
    ghub.deploy()

