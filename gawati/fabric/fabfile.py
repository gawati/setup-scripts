from fabric.api import run
import gawati


def host_type():
    run('uname -s')


def source_deploy():
    # checkout source code
    # build it 
    # upload to server
    ghub = gawati.GitHubSource()
    ghub.checkout()
    ghub.build()
    ghub.deploy()

