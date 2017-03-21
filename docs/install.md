# Installing Open Angel Arena
You have to set up several things before you can run a local instance of OAA for development.

## System Dependencies
Start by installing these programs:
 * [Steam](http://steampowered.com)
 * [nodejs](http://nodejs.org)
 * [Github client](http://desktop.github.com/)

### Text Editors
You can use any editor you want, but it should support `editorconfig` and for better usability `syntax highlighting`
 * [Visual Studio Code](http://code.visualstudio.com/)
 * [Sublime Text 3](https://www.sublimetext.com/3/)
 * [Atom](https://atom.io/)

### Workshop Tools
Install the Dota 2 Workshop Tools.
 * From within steam, right click on `Dota 2` and select `Properties` at the bottom
 * Go to the DLC tab of the window that pops up
 * Check the `INSTALL` box next to `Dota 2 Workshop Tools DLC`

## Setting everything up
Open the `node.js command prompt`. Not `Node.js` itself, but the command prompt.

### Folder definitions
Now we will define 3 paths 
 * `Dota2 installation folder` is something like `C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\` or at ant other drive or install location, but certainly ends with `dota 2 beta`
 * `Dota2 addons folder` is folder named `addons` in `Intallation folder`, so it looks something like `\dota 2 beta\addons`
 * `Open Angel arena folder` is a folder name `oaa` inside of `addons folder`, it contains all the files which are present in this github repo 

**`Dota2 addons folder` and `Open Angel arena folder` may not exist for the first time, they will be created after `Prepare Addon Directory` step**

Final structure sholud look like `C:\(some path to steam library)\Steam\steamapps\common\dota 2 beta\addons\oaa\`

### Navigating with command prompt
Use command `cd` and the undergoing path to navigate,(`cd` works relative to your current path), for example
```
dota 2 beta\addons> cd oaa
```
will go from `Addons` folder to `Open Angel Arena` folder, and
```
dota 2 beta\addons\oaa> cd ../
```
will navigate you back a step to `Addons` folder, and
```
C:\somerandompath> D:
```
will change your current active drive to D:

### Install Node Dependencies
The global install for some reason works very confusingly, so i recommend using local repo for gulp.
Now we navigate into `Dota2 installation folder` folder, and first install dependencies
```
npm install dota2-addon-manager
```

### Download and Deploy Project
To ensure the addons directory is set up, navigate to `Dota2 Installation` folder and run
```
d2am list
```
This will create `Dota2 addons folder` folder and set it up!
Now you have to open `GitHub Client` and using top left `+` button `clone` a repo `OAA` to your newly created `Dota2 addons folder`
To become more familiar with `Git` and `GitHub` you can read a [guide for newcomers](/docs/github-for-noobs.md)
Now we need to link this project to `Dota 2 Tools` with command
```
d2am link
```
After this console shold print out that evrything has been set up!


## Launch Tools
Next we open the actual addon! This is done by right clicking on `Dota 2` from Steam and selecting `Launch Dota 2 - Tools`. It should be the second option on the dropdown below `Play Game`

Open `oaa` from the window that opens, and you're in!

The instructions of testing are present in [Next guide](/docs/testing.md)

Also all the development is discussed in Discord, so please join us at https://discord.gg/WNFBB4d
