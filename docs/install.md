# Installing Angel Arena Allstars
You have to set up several things before you can run a local instance of OAA for development.

## System Dependencies
Start by installing these programs:
 * [Steam](http://steampowered.com)
 * [nodejs](http://nodejs.org)
 * [Github client](http://desktop.github.com/)
 * [Sublime Text 3](http://www.sublimetext.com/) **optional**

Install the Dota 2 Workshop Tools.
 * From within steam, right click on `Dota 2` and select `Properties` at the bottom
 * Go to the DLC tab of the window that pops up
 * Check the `INSTALL` box next to `Dota 2 Workshop Tools DLC`

## Setting evrything up
Open the `node.js command prompt`. Not `Node.js` itself, but the command prompt.

### Navigate with command promt
Now we will define 3 paths 
 * `Dota2 installation folder` is something like `C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\` or at ant other drive or install location, but certainly ends with `dota 2 beta`
 * `Dota2 addons folder` is folder named `Addons` in `Intallation folder`, so it looks something like `\dota 2 beta\addons`
 * `Open Angel arena folder` is a folder name `oaa` inside of `addons folder`, it contains all the files which are present in this github repo  

**Navigating with command prompt**: using command `cd` and the undergoing path to navigate, for example
```
dota 2 beta\addons> cd oaa
```
will go from addons folder to `Open Angel Arena` folder, and
```
dota 2 beta\addons\oaa> cd ../
```
will navigate you back a step to `Addons` folder

### Install Node Dependencies
The global install for some reason works very confusingly, so i recommend using local repo for gulp.
Now we navigate into `Open Angel Arena` folder, and first install global dependencies
```
npm install -g gulp gulp-cli dota2-addon-manager
```
And then create local repo with dependencies
```
npm install gulp gulp-dota2-npc
```

### Prepare Addon Directory
To ensure the addons directory is set up, navigate to `Dota2 Installation` folder and run
```
d2am list
```
and if it show that `oaa` if ready, then run
```
d2am link
```
leave the command prompt open, we'll come back to it.


## Launch Tools
Next we open the actual addon! This is done by right clicking on `Dota 2` from Steam and selecting `Launch Dota 2 - Tools`. It should be the second option on the dropdown below `Play Game`

Open `oaa` from the window that opens, and you're in!

The instructions of testing are present in [Next guide](/docs/testing.md)

Also all the development is discussed in Discord, so please join us at https://discord.gg/E6f6TCe
