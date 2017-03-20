# Installing Open Angel Arena
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

### Folder definitions
Now we will define 3 paths 
 * `Dota2 installation folder` is something like `C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\` or at ant other drive or install location, but certainly ends with `dota 2 beta`
 * `Dota2 addons folder` is folder named `Addons` in `Intallation folder`, so it looks something like `\dota 2 beta\addons`
 * `Open Angel arena folder` is a folder name `oaa` inside of `addons folder`, it contains all the files which are present in this github repo 
`Dota2 addons folder` and `Open Angel arena folder` may not exist for the first time, so don't be afraid to create them
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

### Download Project
This is simple, you have to open `GitHub Client` and using top left `+` button `clone` a repo with `OAA` to your newly created `Open Angel arena folder`


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
