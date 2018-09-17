# GitHub Contibuting Guide

Updated 2017-12-05

[< Git][0]

## Intro
This is an introduction to GitHub and Git on the example of contributing to OpenAngelArena. Nearly all of the implementation (from KV files, localization, scripts, graphics, to models) can be streamlined by using a very basic software tool called a Version Control System (VCS). The one we're using is called Git and the repository (server storage) we are using is called GitHub. Essentially, Git enables the development teams to branch out and work on the exact same files as each other without overwriting each other's work. Also, every person can have multiple development branches of the same files available simultaneously using only a couple very basic commands. This enables one to modify files in a development branch without effecting the others (like if you wanted to test abilties you script but didn't want to have to overwrite and manually back up everytime you change something). Furthermore, Git tracks history, so if you make a mistake, you can just reset to ANY point in the development (even if you delete files). Yes it's going to take some effort to learn.

## Terminology
At this point just familiarize yourself with the following terminology:

- Add - Move changes from the working directory to the staging area.
- Branch - A branch represents an independent line of development.
- Checkout - Switches between branches.
- Clean -  Removes untracked files
- Clone - Creates a copy of an existing Git repository.
- Commit - Takes the staged snapshot and commits it to the project history. (Add - Commit)
- Fetch - Downloads a branch from another repository, without integrating it into your local repository.
- Forking - Gives any contributor a server-side repository.
- Git - Version control system (VCS) for tracking and coordination 
- GitHub - A collaborative software development environment based on the Git VCS.
- GitHub Desktop - Software designed for users to manage their GitHub.
- Init - Initializes a new local repository.
- Local - The local repository.
- Master - The default development branch. Whenever you create a git repository, a branch named master is created, and becomes the active branch.
- Origin - Alias for the URL of the remote repository.
- Powershell - A command-line interface for Git in Windows.
- Pull Request - Provides interface for discussing proposed changes before integrating them into the official project.
- Push - Push commits from one repository to another.
- Remote - The remote repository.
- Repository - A collection of commits, branches, and tags.
- Snapshot - Current state or content of something.
- Staging - Marking files the user wishes to commit.
- Tag - Marks a particular point in the commit chain.
- Tracked files - Any files that were in the latest snapshot.
- Untracked files - Unstaged files not in the last snapshot.

## Getting Started

### Setup

First, follow the [Installation Process](/docs/setup/install.md) in order to create a Fork of openangelarena/oaa to work from.
If you do not already have a GitHub.com Account, create one [here](https://GitHub.com/join).

## Forking
Forking creates a simultaneous instance of oaa within your own GitHub repository. After logging into github.com, do the following:
- Goto github.com/OpenAngelArena/oaa.
- Click "Fork" at the top corner.
- Choose where to Fork: Fork OpenAngelArena/oaa to YOURUSERNAME/oaa
- Done! If you go to `GitHub.com/YOURUSERNAME/oaa` you'll see your own fork of [OpenAngelArena/oaa].

### Cloning
Also described in the Installation Process, cloning copies your fork to your computer with the GitHub client (or by clicking "Clone or Download" on the main page of `GitHub.com/openangelarena/oaa`. As mentioned, you can do basic things with the GitHub Client, but you will want to familiarize yourself with the command-line. GitHub Client comes with a built-in version of PowerShell (a command-line interface which enables you to type Git commands). You should have already done the following during the Installation Process:

- Open the GitHub Client you installed earlier in [install.md](/docs/setup/install.md).
- Click settings.
- Change the settings how you like it (e.g. Change to Dark mode).
- While in settings, changing the default shell to PowerShell.
- Click Save.
- Click on the "+" in the upper left corner.
- Select Clone.
- Select your Account and the forked `oaa` repository.
- Clone your repo to \dota 2 beta\addons
- Verify Clone to your repo.
Now we should have a local copy of your fork of [OpenAngelArena/oaa]

### Open Git Power Shell
Git Power Shell enables you to control Git using a variety of commands. You can open Git Power Shell in a number of ways:
  - Desktop shortcut labelled Git Shell.
  - Startmenu shortcut labelled Git Shell.
  - CMD `%USERPROFILE%\AppData\Local\GitHub\GitHub.appref-ms --open-shell`
  - Right-Click on your repository at 'GitHub.com/YOURUSERNAME/oaa' and select `Open in Git Shell`

 
### Finish Installing oaa
Continue the [Installation Process](/docs/setup/install.md) from the beginning of this tutorial after the "Get the Addon" section (we're skipping that section entirely).

### Getting Started
To be able to work on your own stuff but still have all the newest changes and to have a nice and organized repository, git features Branches. For more information about Branches, read [Git Branching - Branches in a Nutshell](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell).

#### Remotes and Updating

Let's first look at the different remotes we have by typing 'git remote -v':
  ```
   git remote -v
  origin  https://GitHub.com/YOURUSERNAME/oaa (fetch)
  origin  https://GitHub.com/YOURUSERNAME/oaa (push)
  ```
We start out with one remote named "origin". That's our Fork that we made from before.

In order to stay up-to-date with the official OpenAngelArena/oaa (the official one), just add another remote like this:
 ```
  git remote add OpenAngelArena https://GitHub.com/OpenAngelArena/oaa
 ```
 You do not have to call this Remote OpenAngelArena, you can call it whatever you want. Now let's get the newest changes from [OpenAngelArena/oaa]:
  ```
   git pull OpenAngelArena master
  From https://GitHub.com/OpenAngelArena/oaa
   * branch            master     - FETCH_HEAD
  Already up-to-date.
  ```
#### Pushing
When updating, the newest changes are downloaded from OpenAngelArena/oaa to our [local] [master] [branch]. Now push them to your repo YOURUSERNAME/oaa on GitHub:
```
 git push
Everything up-to-date
```

### Workflow
When working, you want to keep two Branches. The first is your local master branch. Switch to it using:
```
 git checkout master
Your branch is up-to-date with 'origin/master'.
Switched to branch 'master'
```
Before changing any of the files, you should create and switch to your new branch:
```
 git checkout -b awesome-branch
Switched to a new branch 'awesome-branch'
```
Now you can do your changes!

To commit your changes you can either use GitHub Desktop or do
```
 git commit YOUR CHANGED FILES -m "WHAT YOU CHANGED" -m "A OPTIONAL EXTENDED DESCRIPTION"
[GitHub-for-noobs 3be214d] more changes
 1 file changed, 19 insertions(+)
```

or you add all files to the commit
```
 git add YOUR CHANGED FILES
```
and commit all of them together
```
 git commit -m "WHAT YOU CHANGED" -m "A OPTIONAL EXTENDED DESCRIPTION"
```

Now push your changes to GitHub
```
 git push
Counting objects: 4, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 600 bytes | 0 bytes/s, done.
Total 4 (delta 3), reused 0 (delta 0)
remote: Resolving deltas: 100% (3/3), completed with 3 local objects.
To https://GitHub.com/Chronophylos/oaa
   1554bf2..3be214d  GitHub-for-noobs - GitHub-for-noobs
```

### Creating a PR

To create a PR goto [OpenAngelArena/oaa](https://GitHub.com/OpenAngelArena/oaa) on GitHub
- Click 'New Pull Request'
- Click `compare across forks`
- Click `head fork` and choose your Repository
- Click `compare` and select your Branch
- Now fill in the form
- 'Create pull request' and you're done!

## Links
- [Read the entire Pro Git Book](https://git-scm.com/book/en/v2)!
- [Git on GitHub](https://GitHub.com/git/git)
- [Wikipedia](https://en.wikipedia.org/wiki/GitHub)
- [Git Questions?](https://stackoverflow.com/questions/tagged/git).
- [OpenAngelArena/oaa Master Repo](https://GitHub.com/OpenAngelArena/oaa)

### Authors
Author Discord@Chronophylos#5199
Editor Discord@Warpdragon#9105

[0]: README.md
