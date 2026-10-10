Truth & Beauty Smooth Slider
─────────────────────────────

Slide an object along one or more of its axes when touched, slide back when touched again.

Drag and drop the optimized Smooth Slider script into an object's Contents to enable
smooth sliding of the object in any direction for a specified distance.

A smooth sliding motion is achieved by using the LSL function 'llSetKeyframedMotion' (KFM).

Settings and customization are saved in the object's linkset datastore and persist
across resets, deletions, and re-rez.

The Truth &amp; Beauty Smooth Slider is available on the Second Life Marketplace at https://marketplace.secondlife.com/p/Truth-Beauty-Smooth-Slider/28771420

This product contains an optimized Smooth Slider LSL script and an example object containing
the script. The example object can be used to familiarize yourself with the operation and usage.

Features
─────────

- Smooth slide
- Auto configures
- Slide along any axis or combine to slide in any direction
- Can slide across region boundaries
- Can slide long distances (default maximum ~1000 Meters)
- Menu system to customize settings
    - Can be configured to slide along any axis
    - Can configure the slide distance
- Settings are saved in the object's linkset datastore
    - Customized settings persist across resets etc
- Audio clips are played during movement, one for opening and one for closing
    - Default audio clips are a door opening and a door closing
    - Customize the audio clips by dropping sound files named "Open" and "Close" in the object Contents
- Collisions with other nonphysical or keyframed objects are ignored
- Collisions with physical objects will be computed and reported
    - The sliding object will be unaffected by those collisions
    - The physical object will be affected
- Open Source LSL script, can view and modify
    - MIT License

Requirements and Limitations
─────────────────────────────

The owner must be able to modify the object and scripts must be enabled on the parcel.

Slides the entire object/linkset.

The 'Slider' script will set the object physics shape to Convex Hull and disable physics. Objects that require physics to be enabled or require a physics shape other than Convex Hull will not work with this script.

Usage
──────

Drop the 'Slider' script into an object's Contents.

The default settings allow anyone to slide the object by touching it. A second touch will slide the object back to its original position. By default the object slides along its X-axis and slides the size of its X-axis length.

The owner of the object or members of the object's group can access a dialog menu with a long touch (click and hold for 2 seconds before releasing the mouse button).

An example Smooth Slider object is included. The example Smooth Slider is a single prim. Drag and drop the 'Truth & Beauty Smooth Slider (example, rez me)' object from your inventory onto the ground. Click to slide, long click to open the dialog menu.

Menu
─────

The Smooth Slider dialog menus provide control buttons to:

- ENABLE/DISABLE the Slider
- Restrict access to OWNER, GROUP, or PUBLIC
- Set the slide axis or combine axes to slide in any direction
- Reverse the orientation of slide movement
- Enable multi-dimensional slide or slide along a single axis
- Control the slide direction, distance, and speed

The Smooth Slider dialog menu control buttons:

- 'DISABLE'
    - Disable the slide, only the dialog menu will be available
- 'ENABLE'
    - Enable the slide, touches will trigger slides
- 'OWNER'
    - Restrict access to the Owner of the object
- 'GROUP'
    - Restrict access to the Owner of the object or members of the object's group
- 'PUBLIC'
    - Anyone can slide the object with a touch, owner and group members can access the menu
- 'X-AXIS'
    - Sets the slide axis to the object's X-axis (this is the default)
- 'Y-AXIS'
    - Sets the slide axis to the object's Y-axis
- 'Z-AXIS'
    - Sets the slide axis to the object's Z-axis
- 'REVERSE'
    - Reverses the orientation of slide movement
- 'FORWARD'
    - Returns the orientation of slide movement to forward after reversing
- 'MULTI'
    - Enable multi-dimensional slide
- 'SINGLE'
    - Slide along a single axis
- 'SLIDE'
    - Slides the object, closing if open or opening if closed
- 'CLEAR'
    - Clear the linkset datastore, reset to default settings, restore to original position
- 'RESET'
    - Resets the script, leaving the datastore intact
- 'DIRECTION'
    - Control the slide direction
- 'DISTANCE'
    - Select or enter a slide distance
- 'SPEED'
    - Select or enter a slide speed
    - 'CONSTANT' button on the SPEED menu fixes speed regardless of distance changes
    - 'VARIABLE' button on the SPEED menu causes speed to increase as distance increases
- 'EXIT'
    - Exit the dialog menu and return to the active state

Linkset Datastore
──────────────────

The Truth & Beauty Smooth Slider can be customized via the dialog menus. These customizations are saved in the Linkset Datastore. This feature allows the Slider to store up to 128 Kilobytes of persistent storage directly on the root prim.

The key benefit of using the Linkset Datastore to save customizations is the persistence of the saved settings. Saved customization persists across resets, script changes, even script deletion as this data is associated with the root prim rather than the script.

For example, using the dialog menus to change the slide axis to vertical and slide distance to 10 meters with constant speed would store the axis, distance, and constant speed settings in the prim's datastore. These customizations would survive a script reset, they would survive an update in which the existing 'Slider' script was deleted and a new 'Slider' script dropped into the object's Contents. They even survive if the object is taken into inventory and re-rezzed.

* Inventory & Re-rez: Taking an object to inventory and re-rezzing it will not alter or erase any saved keys.
* No-Copy vs. Copy Items: The data persists regardless of item permissions. If you shift-drag copy the object in-world, or pull multiple copies from a "copyable" inventory item, all copies will inherit the exact dataset stored at the time the object was saved.
* Script Resets & Deletions: You can manually reset scripts, use 'llResetScript()', or even delete the scripts entirely from the object; the data will still remain intact inside the prim.

Slider Linkset Datastore
─────────────────────────

Currently the 'Slider' settings saved in the Linkset Datastore are as follows:

- Access restrictions
    - Public, Group, or Owner Only access
- Slide speed rate
    - Whether the slide speed increases with an increase in distance or remains constant
- Distance to slide
    - How far the object slides 
- Duration of the slide
    - How long it takes to complete the slide
- Speed of the slide
    - How fast the object slides
- Slide axis
    - Along which axis the object slides
- Slide orientation
    - Whether the object slides in a positive or negative direction

Slider Volatile Memory
──────────────────────

Truth & Beauty Smooth Slider settings not stored in the Linkset Datastore are maintained in script memory and do not persist across resets etc. This is intentional and allows some Slider properties to be altered and re-saved with a script reset.

For example, to change the Slider's setting for the "closed" position and rotation of the object, simply move the object to the location you wish to set for its closed position and rotate it to set its desired home rotation. Once positioned and rotated, reset the scripts using the dialog menu (Long touch -> RESET) or manually (Right click -> More -> More -> Scripts -> Reset Scripts).
