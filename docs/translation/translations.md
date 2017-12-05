# Writing and Translations

Updated 2017-12-05

[< Translation][0]

There's a lot of text in OAA, varying between single word titles to paragraph descriptions.

## Languages 
We are currently translating Open Angel Arena to:
- Chinese
- Czech
- German
- Hungarian
- Polish
- Portuguese
- Russian
- Spanish

## Transifex
We are using Transifex to handle all translation work. In order to start translating, you need to:
- Create an account on [transifex](https://www.transifex.com/) (Use the same name as in Discord)
- Go to [our project](https://www.transifex.com/open-angel-arena/open-angel-arena/)
- Click on `Help Translate "Open Angel Arena"` and follow the instructions
- Wait to be accepted

## Translating
We want our translations to blend in with the original Dota so you need to learn the "translation style" of your language. For example, item names are not translated in all languages. In that case, we will also keep the original english name.
Many strings can be copied from the [official Dota 2 website](http://www.dota2.com/items/) (you can select the language in the top right), which is also great to learn the translation style.
Sometimes it is hard to find out where a string will be used in the game by just reading it. If that happens you can take a look at the key (below the box in which you enter your translation). For example, `DOTA_Tooltip_Ability_item_bfury_2_Description` is the tooltip description of the item Battlefury.

## Testing translations
After translating you want to test your translated strings. 

First of all, you need to [create environment variables](http://www.forbeslindesay.co.uk/post/42833119552/permanently-set-environment-variables-on-windows), `TRANSIFEX_USER` and `TRANSIFEX_PASSWORD`. `TRANSIFEX_USER` must be set to your username on transifex and `TRANSIFEX_PASSWORD` is your transifex password.
It is also possible to use an [authentication token](https://www.transifex.com/blog/2017/api-authentication-tokens/). If you want to use that set `TRANSIFEX_USER` to `api` and `TRANSIFEX_PASSWORD` to the token. This is also the way to go if you sign in with Github, Google or Facebook.

Open a **new** command prompt in your `oaa` folder and run `node scripts/generate-translations.js`.
Start the game and check your strings.

[0]: README.md
