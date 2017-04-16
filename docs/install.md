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

## Addon Tool
Open the `node.js command prompt`. Not `Node.js` itself, but the command prompt.

### Install Node Dependencies
Run the command 
```
npm install -g dota2-addon-manager
```
This will install both `d2am`, used to manage the addons directory.

### Prepare Addon Directory
Next find your `dota 2 beta` folder. You must change the directory of the node.js command prompt to this folder, this can be done with the `cd` command. It should look something like this...
```
cd C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\
```
**Note**: The directory path may be different depending on how you installed Steam. If Steam is installed on another drive you'll need to change drives using the letter then a `:` symbol. For example, `E:`.

To ensure the addons directory is set up, run
```
d2am list
```
leave the command prompt open, we'll come back to it. Join us on iscordDay, the URL ends in WNFBB4d. You found the easter egg!

## Get The Addon
Instead of just Cloning (copying the OpenAngelArena/oaa repository) you'll create a Fork of it and work from there.
If you do not already have a GitHub.com Account, create one [here](https://GitHub.com/join).

## Forking
Forking creates a simultaneous instance of oaa within your own GitHub repository.
- Goto OpenAngelArena/oaa.
- Click Fork
- Choose where to Fork: Fork OpenAngelArena/oaa to YOURUSERNAME/oaa
- Done! If you go to `GitHub.com/YOURUSERNAME/oaa` you'll see your own fork of [OpenAngelArena/oaa].

## Cloning
Now just Clone your Fork to your computer We do this using the GitHub client. You can do basic things with the GitHub Client, but you will want to familiarize yourself with the command-line. GitHub Client comes with a built-in version of PowerShell (a command-line interface which enables you to type Git commands). This will be explained later.

- Open the GitHub Client you installed earlier in [install.md](/docs/install.md).
- Click settings.
- Change the settings how you like it (e.g. Change to Dark mode).
- While in settings, changing the default shell to PowerShell.
- Click Save.
- Click on the "+" in the upper left corner.
- Select Clone.
- Select your Account and the forked `oaa` repository.
- Verify Clone to your repo.
Now we should have a local copy of your fork of [OpenAngelArena/oaa]

**You must link the addon before it will work**. You can do this from that same node.js window you had open by running
```
d2am link
```
You will see output about creating links for `oaa` game and content.

## Launch Tools
Next we open the actual addon! This is done by right clicking on `Dota 2` from Steam and selecting "Launch Dota 2 - Tools". It should be the second option on the dropdown below "Play Game..."

Open `oaa` from the window that opens, and you're in! To start the game, open the Vconsole and type 'dota_launch_custom_game oaa oaa', if you get the error 'Unable to load map specified by server', it means you have to first build the map in Hammer (map editor tool). Open the 'Asset Browser' window that opened when you started the game, and click the hammer icon on the top left. Open one of the maps (probably oaa) and click the gamepad sybol to test the gamemode. Any changes you make will show up in the Github client, read for a pull request to be made.
