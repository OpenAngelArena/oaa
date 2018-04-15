# Custom Model Workflow

Updated 2018-02-26

[< Models][0]

## Required tools

- Blender

- Dota 2 Tools

- Source Film Maker

- Source import/export plugin for Blender

## Exporting existing models into Blender

1. Get the armature/model (fbx file or other) from [Valve][http://www.dota2.com/workshop/requirements].

2. Open Dota 2 Tools and from there open Source Film Maker.

3. Create a new session and select the dota map. 

4. Drag the dota 2 animated unit/hero model into the map.

5. In the outliner import sequences and export them as animations (dmx files)

## Correcting orientation/scale of existing models in Blender

1. Open the fbx file at 100x scale.

2. Remove the un-usable armature (delete the skeleton.)

3. Select all R-otate, X-axis, 90 degrees. Select All -> Ctrl + A (Apply) rotation (he should be vertical).

4. Import the Bind animation.

5. Select entire skeleton.

6. Go into pose mode. Press Alt+G, Alt+R, Alt+S, to clear Location/rotation/scale.

7. Press I (Insert Keyframe) -> LocRotScale

8. In Object Mode rotate X -90, Rotate Z -90

9. Ctrl + A (Apply) Rotation

10. Alt + G, Alt + R, Alt + S (he should stay upright)

11. Modifieris should retain "Armature". Select the object for each item you need bound in the modifier and bind it.

12. Edit/create/weight paint/wrap/texture to your heart's delight.

13. **Save Blend file frequently. Keep this file backed up safely.**

### Import to Tools

1. When exporting existing Dota 2 models as fbx file export to scale 0.01x. When exporting other models different scales may be required.

2. Put models (fbx file) into ``oaa/models/<name of folder>``. Put animations (dmx file) into ``oaa/models/<name of folder>/anims``. Put your images (png files) into ``oaa/materials/models/<name of folder>``.

3. Open Dota 2 Tools

4. Open the Model Editor. Create new model from mesh (this crashes the model editor but does actually create the vmdl).

5. In the Assets Manager, type in the name of your model, you should see it. Open the model by double clicking.

6. If you cannot see your model, look around. Sometimes the model editor offsets the model by a thousand or so units. You can "adjust" these in the properties panel on the right. Some numbers that seem to work for Valve's Dota 2 models are:

- Translation: -1837, 0, -1304
- Rotation: 0, 0, 135

7. If materials fail to show up simply create new Material Remaps using the images in the dota 2 materials folder. 

8. Once everything looks normal start importing animations, give them actions (ex. ACT_DOTA_RUN) and other parameters such as sounds and particles.

9. Compile the map and test in game.

### Tutorials:

1. [Really good modelling/rigging tutorial playlist (YouTube)][1]
2. [Fixing skeletons and importing (YouTube)][2]

[0]: README.md
[1]: https://youtu.be/aAO4C_8y0w8
[2]: https://youtu.be/x5u8CmXUrYQ
