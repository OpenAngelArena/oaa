# Working with KV Files

Updated 2017-12-05

[< KV][0]

Welcome to the wonderful world of KV (Kivy), or KeyValue language. The name implies its structure: Keys on the left, Values on the right, forming pairs. KeyValues are stored information used primarily by LUA scripts. When invoked, these scripts trigger actions, pulling from the KeyValues when required
## Tools You'll need

### Advanced PlainText editor

SublimeText 3 (free software)
- Setup SublimeText 3 to highlight using Dota KV:
  - [Install Package Control](https://packagecontrol.io/installation)
  - Ctrl+Shift+P -> Package Control: Install Package -> Dota KV
  - Ctrl+Shift+P -> Set Syntax Dota KV

Atom (free software) 
- Settings -> Install: search for language-dotakv.

### Arhowk.github.io (website)
- Easy online Sample Debugger for KV language.

### Git/Github (free software)
Git is a version control system (VCS) used in the oaa project as a way of updating everyone's game as work is done ("oaa" sending game-data downstream to users) and as a way to receive contributors' work (users sending game-data upstream to "oaa")
Github is an app/website used to manage "oaa"s files.

### Node.js (custom software)
For compiling lots of KeyValue files into a single file (such as with npc data found in the /npc directory)
Certain specific KV files go into specific directories such as "npc/Items" and "npc/Abilities". A console package called "Node.js" is used to compile (aka gulp) individual KV files into the large combined files used by Dota 2. Run "Node.js Command Prompt".
Commands:
- npm i - The initial setup command.
- gulp - compiles all the individual files from within a directory e.g. "npc/Items" into a single file e.g. "npc/npc_items_custom.txt"

## Structure
Here's a very simplified breakdown of what you should expect to see when you look at a KeyValue file.
```
"ParentOne"
{
    // <- Notice the indent. Implies child-parent relationship of the {} enclosed set.
    "Key"               "Value"
    "Key"               "Value"
    // The following is an array of values.
    "Key"               "1 2 3 4 5 6"
    // 
    "ParentTwo"
    {
        // These values are the child of the parent element so they indent further.
        "Key"           "Value"
        "Key"           "Value"
        "Key"           "Value"

    }
}
```

## Dota 2 KV Guidelines
- "ID" is one of the few required Keys for NPC data. It is also a Unique ID. Do not duplicate "ID"s, do not change "ID"s.
- "BaseClass" is also a required Keys for NPC data. It defines the way in which the set of KeyValues hooks into the rest of Dota 2.
- Nesting - Indent your code when nesting, please. It helps everyone visualize the database's structure.
- Comment Code - If you comment, then other contributors will know what's up. Commenting can also be used to remove data without deleting it. Comment code by putting "//".
- Debug frequently
- Whether you're editing existing KV files or creating new ones, you should write them and also keep them as seperate files even after Gulping them together into a single master file e.g. "npc_abilities_override.txt". 
- If an array of values has the same values, you can reduce them to a single value, like:
```
"SomeAbility"
{
    "Damage"                "0 0 0 0 0"
    // Can be reduced to:
    "Damage"                "0"
}
```
- "var_type" stands for variable type, and it's "Value" defines the acceptable subset of values in the pair following it.
```
"MegaBuster"
{
    "var_type"              "FIELD_INTEGER"
    // Integers are whole numbers. The "Damage" Key must be paired with whole number Values.
    "Damage"                "2000"
}
```

## Workflow

### Setup
Ideally you should use Git to create your own development branch (see Git tutorial). This way you can change any files you want without disturbing your master copy of oaa.

### Author
When making KV files, you should always start with a valid, up-to-date template, many of which can be found at www.ModDota.com. 

### Compile
When you think you've got your files the way you want, run Node.js and gulp. This generates the file used by the game.

### Debug
Copy the contents of the KeyValue file you wish to debug into arhowk.github.io. Fix any errors in the *individual KV files* not in the compiled file. Once you've fixed all the errors, gulp again. This will put the updated KV files into the compiled form again.

### Test in oaa
Launch Dota 2 Tools; Load "oaa" addon; Load Console by pressing "~"; Launch the addon using the following command:
```
"dota_launch_custom_game oaa oaa"
```

[0]: README.md
