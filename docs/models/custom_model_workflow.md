# Custom Model Workflow

Updated 2018-02-26

[< Models][0]

## Required tools

- Blender

- Dota 2 Tools

- Source Film Maker

## Export to Blender

1. Get the armature/model (fbx file or other) from [Valve][http://www.dota2.com/workshop/requirements].

2. Open Dota 2 Tools and from there open Source Film Maker.

3. Create a new session and select the dota map. 

4. Drag any dota 2 animated unit/hero model into the map.

5. In the outliner import sequences and export them as animations (dmx files)

## Working in Blender

1. Open the fbx file at 100x scale.

2. Import the Bind animation.

3. Edit/create/rig/weight paint/wrap/texture to your heart's delight.

4. **Save Blend file frequently. Keep this file backed up safely.**

5. When exporting the new fbx file export to scale 0.01x

6. Put your images into the dota 2 materials folder for later.

### Import to Tools

1. Open Dota 2 Tools

2. Open the Model Editor. Create new model from mesh (this crashes the model editor).

3. In the Assets Manager, type in the name of your model, you should see it. Open the model by double clicking.

4. If you cannot see your model, look around. Sometimes the model editor offsets the model by a thousand or so units. You can "adjust" these in the properties panel on the right.

5. If materials fail to show up simply create new Material Remaps using hte images in the dota 2 materials folder.

6. Once everything looks normal start importing animations, give them actions (ex. ACT_DOTA_RUN) and other parameters such as sounds and particles.

7. Compile the map and test in game.

[0]: README.md
