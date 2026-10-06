// Smooth Object Slide on touch using llSetKeyframedMotion (KFM)
//
// Written 06-October-2026 by Missy Restless <missyrestless@gmail.com>
//

integer   Debug = FALSE;       // Set to TRUE for verbose debug output
rotation  Rot;                 // Initial rotation of the object
vector    Home;                // Initial closed position
vector    Open;                // Open position
float     Distance;
vector    Size;

// Define a sound that plays when the door starts to open; set to NULL_KEY for no sound.
key     SOUND_ON_OPEN  = "e5e01091-9c1f-4f8c-8486-46d560ff664f";
// Define a sound that plays when the door has closed; set to NULL_KEY for no sound.
key     SOUND_ON_CLOSE = "88d13f1f-85a8-49da-99f7-6fa2781b2229";
// Define the volume of the opening and closing sounds
float   SOUND_VOLUME   = 1.0;

moveToTarget(float dst) {
    if (Debug) {
        llOwnerSay("In moveToTarget(dst) with dst = " + (string)dst);
    }
    // Calculate the local translation vector
    vector local_offset = <dst, 0.0, 0.0>;
        
    // Convert local offset to global coordinates based on current rotation
    vector global_offset = local_offset * llGetRot();
        
    // Define the movement keyframe: [offset vector, rotation, duration in seconds]
    float duration = 4.0; // Adjust this number to make it slide faster or slower
    list keyframe = [global_offset, ZERO_ROTATION, duration];
        
    llSetTimerEvent(duration * 2.0);

    // Trigger the smooth motion
    if (Debug) {
        llOwnerSay("Calling llSetKeyframedMotion with keyframe = " + llDumpList2String(keyframe, ", "));
    }
    llSetKeyframedMotion(keyframe, []);
}

default {
    state_entry() {
        Rot = llGetRot();
        Home = llGetPos();

        if (SOUND_ON_OPEN) {
            llPreloadSound(SOUND_ON_OPEN);
        }

        // Set the object physics shape to Convex Hull and Disable physics
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
            PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_CONVEX,
            PRIM_PHYSICS, FALSE
        ]);
        // Get the object's size (length)
        Size = llGetScale();
        // Define the distance to move (using the X dimension of its size)
        Distance = Size.x;
        // Set open position
        Open = Home + <Distance, 0.0, 0.0>;
        if (Debug) {
            llOwnerSay("Distance = " + (string)Distance);
            llOwnerSay("Home     = " + (string)Home);
            llOwnerSay("Open     = " + (string)Open);
        }
    }

    touch_end(integer total_number) {
        state opening;
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

// In this state, the object is in process of sliding open
// Ignore touches while sliding
state opening {
    state_entry() {
        if (SOUND_ON_OPEN) {
            llPlaySound(SOUND_ON_OPEN, SOUND_VOLUME);
        }
        if (SOUND_ON_CLOSE) {
            llPreloadSound(SOUND_ON_CLOSE);
        }
        if (Debug) {
            llOwnerSay("Calling moveToTarget(" + (string)Distance + ") in opening state");
        }
        moveToTarget(Distance);
    }

    timer() {
        llSetTimerEvent(0);
        state open;
    }
}

// State for when the object is fully open
state open {
    state_entry() {
        // Finalize move to open position
        if (Debug) {
            llOwnerSay("Finalize move to open position with call to:\nllSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_POSITION, " + (string)Open + ", PRIM_ROTATION, " + (string)Rot + "])");
        }
        llSetLinkPrimitiveParamsFast(LINK_ROOT, [
            PRIM_POSITION, Open,
            PRIM_ROTATION, Rot
        ]);
    }

    // We will close the object either if it's touched while fully open, or after a time
    touch_end(integer num) {
        state closing;
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

// State for when the object is in the process of sliding close
// Ignore touches while sliding
state closing {
    state_entry() {
        if (SOUND_ON_CLOSE) {
            llPlaySound(SOUND_ON_CLOSE, SOUND_VOLUME);
        }
        if (SOUND_ON_OPEN) {
            llPreloadSound(SOUND_ON_OPEN);
        }
        if (Debug) {
            llOwnerSay("Calling moveToTarget(-" + (string)Distance + ") in closing state");
        }
        moveToTarget(-Distance);
    }

    timer() {
        llSetTimerEvent(0);
        state closed;
    }
}

// State for when the object is closed
state closed {
    state_entry() {
        // Finalize move to closed position
        if (Debug) {
            llOwnerSay("Finalize move to closed position with call to:\nllSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_POSITION, " + (string)Home + ", PRIM_ROTATION, " + (string)Rot + "])");
        }
        llSetLinkPrimitiveParamsFast(LINK_ROOT, [
            PRIM_POSITION, Home,
            PRIM_ROTATION, Rot
        ]);
    }

    touch_end(integer num) {
        state opening;
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}
