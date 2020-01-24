TOOLS AND UTILITIES FOR USE IN THE AUTOMATION FRAMEWORK

resetpillar.py (resets.yaml)

tool used to reset specific pillar items when new salt environment branches are cut in pillar.
we cut new pillar branches when new environments are needed.
branches get cut from other branches. I.E.
    > git checkout -b new_env_branch
The above would be executed from a local cloned branch of salt-pillar. So if we have 'qa' branch checked out, 
the 'new_env_branch' would have exact data as 'qa'.
This is not desirable because we need different passwords, users and other data from environment to environment.

resetpillar.py gets executed by the release/source admin who's cutting the new branch. The reset tool will use
resets.yaml as the definition of what pillar files, keys and values to reset on all new branches.

Ideally this tool could be executed from a pre-commit hook in git.
 



