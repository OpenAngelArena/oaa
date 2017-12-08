# Importing Models from Blender

Updated 2017-12-08

[< Documentation][0]

## Workflow

The Charger custom model includes:

1 Mesh (3D model)
2 Base texture
3 Base material
4 Rigging (armature, a.k.a. bones)
5 Animations

These were the steps taken:
1 The base mesh was modelled using the software Blender. 

2 Using Blender, the mesh was UV unwrapped. The UV layout was exported as a ".png" file. Then, in Photoshop CS3 the layout was divided into separate layers, one for each part of the body (e.g. legs, horns, head, tail, etc). In that same software a new very basic texture was creature, and saved as a ".psd" file (in this case, "charger_texturetest.psd". This file was then opened in Blender to texture the 3D mesh.

3 After texturing, an Armature was created (a.k.a. bones), and the model was rigged.

4 Once the rig was completed, the animation proccess began. Several actions were created (Idle, Run, Death, Channel, and Stunned). 

5 After all the animations were completed, using the "Blender Source Tools 2.9.1" add-on, a mesh with the ".smd" extension was exported, and all the animations were independently exported also as ".smd" files. A new "models" folder was created inside "oaa/content/". Then, the "charger" folder was created, followed by the "anims" folder inside of the "charger" folder. The mesh "charger_test.smd" is inside the "charger" folder, and all the different animations are inside the "anims" folder. Inside "oaa/content/materials/", a new charger folder was created, and the "charger_texturetest.psd" file was added.

6 Now you need to create a new material. Open the Material Editor of the Dota 2 Tools, and create a new material. Change the default texture to  the the texture image (In this case,"charger_texturetest.psd"). Save the new material inside "oaa/content/materials/charger/". It is a ".vmat" file. 

7 In the Model Editor of Dota 2 Tools, you choose "New vmdl from mesh" and choose the "charger_test". This will create the "charger_test.vmdl" file.

8 Open this new file in the Model Editor. In the "Model" tab, click "Add Material Remap", and search for the material we created earlier.

9 In the "Model>Hitboxes" tab, select "Autogenerate hitboxes". 

10 In the "Model>Collision" tab, select "Add Symple Physics" and select the .smd mesh. 

11 In the "Animation" tab, click "Add animation" and select all the animations inside the "oaa/content/models/anims/" folder. On the right menu, you need to add an activity for each animation (search for the "Activity" tab, and click the blue plus sign). All the activities start with "act_dota_". For example, in the "Idle" activity, add a new activity that goes "ACT_DOTA_IDLE". If the activity has a loop, tick the "loop" option. 

12 Save the vmdl file. Too add it to the game, just go to "oaa/game/scripts/npc/units/charger/npc_dota_boss_charger.txt" and change the model from "models/heroes/spirit_breaker/spirit_breaker.vmdl" to "models/charger_test/charger_test.vmdl". Also, change the scale to 1. Bingo. 

## Results

Results were negative. Boss never worked in game due to a "channel animation" bug. Workflow needs updating.
