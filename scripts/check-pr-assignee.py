""" #!/usr/bin/python

import sys, getopt
from github import Github

def main(argv):
    opts, args = getopt.getopt(argv,"r:p:t:")

    for opt, arg in opts:
        if opt == "-p":
            pull = int(arg)
        elif opt == "-r":
            repo = arg.strip()
        elif opt == "-t":
            token = arg.strip()

    print pull, repo

    # First create a Github instance:
    g = Github(token)

    # post a comment to an issue
    if g.get_repo(repo).get_issue(pull).assignee == None:

        g.get_repo(repo).get_issue(pull).create_comment("You forgot to assign your PR! It's a muffin offence, you know...")

if __name__ == "__main__":
    main(sys.argv[1:])
 """