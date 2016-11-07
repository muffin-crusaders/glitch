#!/usr/bin/python

import sys, getopt
from github import Github

def main(argv):
    opts, args = getopt.getopt(argv,"r:p:m:t:")

    for opt, arg in opts:
        if opt in "-m":
            message = arg.strip()
        elif opt == "-p":
            pull = int(arg)
        elif opt == "-r":
            repo = arg.strip()
        elif opt == "-t":
            token = arg.strip()

    print message, pull, repo, token

    # First create a Github instance:
    g = Github(token)

    # post a comment to an issue
    g.get_repo(repo).get_issue(pull).create_comment(message)

if __name__ == "__main__":
    main(sys.argv[1:])
