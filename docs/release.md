# Release Process
It's important to have a standard release process. This is what I do.

### First time setup
There's a few things you only need to do once, but must be done once before updating the game.

 * Understand git. Watch some youtube videos. It's important.
 * Force recompile all
   * Change the Mods filter on the asset browser to only be OAA
   * Select the first item visible
   * Scroll to the end
   * Holding shift, select the last item
   * Right click, `Full Recompile`
 * Install node dependencies
   * from the command line in OAA directory, run `npm i`
 * Build all the maps
 * Setup transifex enviornmental variables if applicable
   * Right click my computer, go to properties
   * Near the bottom there's an environmental variables button
   * Add `TRANSIFEX_USER` and `TRANSIFEX_PASSWORD`

## Testing
Test the fucking game mode. `-addbots` is your friend, kill a boss, `-addpoints` can trigger final duel... Test the game.

## Releasing
First merge all the PR's that are ready and **TEST THE GAME**, I know you wont.

If the map changed, make sure you compile every single version of it and run the minimap generating command.

#### Tagging the release

 * Tag a new release version, `npm version patch` or `npm version minor` depending on if there are large enough gameplay changes to warrant a patch or minor version bump (major bumps are after tournaments). Use `git log` or the GitHub UI to remind yourself what's changed since the last patch.
 * Edit `addon_game_mode.lua` to contain the new version number (it prints when you run the previous command)
 * run `node scripts\generate-translations.js`
 * Ammend the tagged commit with `git ci -a --amend` and continue through when it asks for the commit message. If it opens in vim type `:wq` and hit enter.
 * Delete the no longer correct tag with `git tag -d v3.2.1`, replacing the version with the one you just created
 * Recreate the tag with `git tag v3.2.1`, to be quick you can hit `up, ctrl+left, ctrl+left, del, del, enter` and you'll end up with the right command here.
 * Push the tag, you'll want to do this before starting the patch notes, `git push upstream master --tags`
 * Write the patch notes

#### Patch note format

 * Put the version number at the top in the format of `vX.X.X`
 * Go to https://github.com/OpenAngelArena/oaa/commits/master and make sure your newly tagged commit is there
 * Go through each commit since the most recent tag before that, bottom up, and copy them into a text file
 * The format is `* [commit message] (#[PR number]) - [author]`. Most of the time the commit message will already have the PR number. Indent each with 1 space.
 * Make sure the messages don't suck
 * Place the hash of the tag commit at the bottom, you can get it by clicking on the commit in the github UI and copying it from the URL

It should look a lot like this
```
v3.2.1

 * Most of the Rest of the Bottles (#2150) - Satsaa
 * Subtle Sohei dash value fix (#2154) - Baumi
 * Fix errors from dota update (#2157) - imaGecko
 * Remove attribute Status Resistance (#2170) - carlosrpg

cfaabaccfadc1f29e38d9a8448af4badb983c850
```

#### Update the game
You should know how to do this. Copy and paste the patchnotes in and wait.

#### Spread then news
It's important.

 * While it's uploading, put a \`\`\` before and after the patchnotes.
 * Once the upload finishes it will automatically open the game in a new tab
 * Copy and paste the URL and put it at the end of the file

It should look like this now, except without spaces between the "\`"s
```
` ` `
v3.2.1

 * Most of the Rest of the Bottles (#2150) - Satsaa
 * Subtle Sohei dash value fix (#2154) - Baumi
 * Fix errors from dota update (#2157) - imaGecko
 * Remove attribute Status Resistance (#2170) - carlosrpg

cfaabaccfadc1f29e38d9a8448af4badb983c850
` ` `
https://steamcommunity.com/sharedfiles/filedetails/?id=881541807
```

 * Paste it everywhere
   * `#patch-notes` in community discord
   * `#progress` in developer discord
   * `#oaa_discussion_and_other_things` in the minimis discord
