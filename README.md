# Slider

Slide an object along one of its axes when touched, slide back when touched again.

A smooth sliding motion is achieved by using the LSL function `llSetKeyframedMotion` (KFM).

## Features

- Smooth slide
- Auto configures
- Can slide across region boundaries
- Can slide long distances (default maximum ~1000 Meters)
- Menu system to customize settings
    - Can be configured to slide along any axis
    - Can configure the slide distance
- Settings are saved in the object's linkset datastore
    - Customized settings persist across resets etc
- Collisions with other nonphysical or keyframed objects are ignored
- Collisions with physical objects will be computed and reported
    - The sliding object will be unaffected by those collisions
    - The physical object will be affected
- Open Source LSL script, can view and modify
    - MIT License

## Requirements and Limitations

The owner must be able to modify the object and scripts must be enabled on the parcel.

Slides the entire object/linkset.

The `Slider` script will set the object physics shape to Convex Hull and disable physics.
Objects that require physics to be enabled or require a physics shape other than Convex Hull
will not work with this script.

## Usage

Drop the `Slider` script into an object's Contents.

The default settings allow anyone to slide the object by touching it. A second touch will slide the object back to its original position. By default the object slides along its X-axis and slides the size of its X-axis length.

The owner of the object or members of the object's group can access a dialog menu with a long touch (click and hold for 2 seconds before releasing the mouse button).

## Menu

The Slider dialog menu provides the following Slider control buttons:

- `DISABLE`
    - Disable the slide, only the dialog menu will be available
- `ENABLE`
    - Enable the slide, touches will trigger slides
- `OPEN`
    - Slide the object to its open state
- `CLOSE`
    - Slide the object to its closed state
- `OWNER`
    - Restrict access to the Owner of the object
- `GROUP`
    - Restrict access to the Owner of the object or members of the object's group
- `PUBLIC`
    - Anyone can slide the object with a touch, owner and group members can access the menu
- `X-AXIS`
    - Sets the slide axis to the object's X-axis (this is the default)
- `Y-AXIS`
    - Sets the slide axis to the object's Y-axis
- `Z-AXIS`
    - Sets the slide axis to the object's Z-axis
- `CLEAR`
    - Clear the linkset datastore, reset to default settings, restore to original position
- `DISTANCE`
    - Select or enter a slide distance
- `EXIT`
    - Exit the dialog menu and return to the active state
