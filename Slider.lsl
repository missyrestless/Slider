// Object Slider
//
// Written 05-October-2026 by Missy Restless <missyrestless@gmail.com>
// Based on sliding door script by by Omei Qunhua
//
// Ignore touches while sliding

rotation  Rot;                 // Initial rotation of the object
vector    Home;                // Initial closed position
vector    Offset;              // Populated with the move distance stored in the axis position
integer   AUTO_CLOSE_TIME = 0; // Can be zero if no auto-close is desired
integer   Phantom; 
integer   Physics; 
integer   RotateX; 
integer   RotateY; 
integer   RotateZ; 
integer   TargetID;
integer   Debug = TRUE;        // Set to FALSE to turn off debugging output

outputDebug(vector Target) {
    vector Position = llGetPos();
    llOwnerSay("Current position: " + (string)Position);
    llOwnerSay("The distance between current position and target position is: " + (string)llVecDist(Position, Target));
}

// Set the object PHANTOM and PHYSICAL and start moving it
startMove(vector Target) {
    // Do this first, to avoid the object dropping
    // llSetBuoyancy(1.0);
    // Lock rotations while moving
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y | STATUS_ROTATE_Z, FALSE);

    // Make sure oject is phantom and physics enabled
    llSetStatus(STATUS_PHANTOM, TRUE);
    llSetStatus(STATUS_PHYSICS, TRUE);
    TargetID = llTarget(Target, 0.25);
    // Little pause to allow server to make potentially large linked object physical
    llSleep(0.1);

    // Start the move
    if (Debug) {
        outputDebug(Target);
        llOwnerSay("Calling llMoveToTarget(" + (string)Target + ", 5.0)");
    }
    llMoveToTarget(Target, 5.0);

    // Start a timer. We will end the move after this time.
    llSetTimerEvent(6);
}

endMove(vector Target) {
    // Return the object to original phantom and physical states, do a final confirmatory move
    llSetTimerEvent(0);
    llSetStatus(STATUS_PHYSICS, Physics);
    llSetStatus(STATUS_PHANTOM, Phantom);
    // llSetBuoyancy(0.0);
    llSetStatus(STATUS_ROTATE_X, RotateX);
    llSetStatus(STATUS_ROTATE_Y, RotateY);
    llSetStatus(STATUS_ROTATE_Z, RotateZ);
    if (Debug) {
        outputDebug(Target);
        llOwnerSay("Calling llSetPrimitiveParams([PRIM_POSITION, " 
            + (string)Target + ", PRIM_ROTATION, " + (string)Rot + "])");
    }
    llSetPrimitiveParams([ PRIM_POSITION, Target, PRIM_ROTATION, Rot ]);
}

removeTarget(vector tpos, vector opos) {
    llOwnerSay("Object is within range of target");
    llOwnerSay("Target position: " + (string)tpos + ", object is now at: " + (string)opos);
    llOwnerSay("this is " + (string)llVecDist(tpos, opos) + " meters from the target");
    llTargetRemove(TargetID);
}

default {
    state_entry() {
        vector Scale = llGetScale();
        Rot = llGetRot();
        Home = llGetPos();
        Phantom = llGetStatus(STATUS_PHANTOM);
        Physics = llGetStatus(STATUS_PHYSICS);
        RotateX = llGetStatus(STATUS_ROTATE_X);
        RotateY = llGetStatus(STATUS_ROTATE_Y);
        RotateZ = llGetStatus(STATUS_ROTATE_Z);

        // Find the middle sized dimension of the object
        // This determines the axis to move on, and the distance to move
        list lx = llListSort( [Scale.x, <1,0,0>, Scale.y, <0,1,0>, Scale.z, <0,0,1> ], 2, TRUE ); 
        // Apply the distance to move to the appropriate dimension
        Offset = llList2Vector(lx, 3) * llList2Float(lx, 2);
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

// In this state, the object is in process of opening
state opening {
    state_entry() {
        startMove(Home + Offset * Rot);
    }

    timer() {
        endMove(Home + Offset * Rot);
        state open;
    }

    at_target(integer tnum, vector targetpos, vector ourpos) {
        if (tnum == TargetID) {
            removeTarget(targetpos, ourpos);
        }
    }

    not_at_target() {
        llOwnerSay("Not there yet - object is at " + (string)llGetPos());
    }
}

// State for when the object is fully open
state open {
    state_entry() {
        // Close the object after this time (or not, if value is zero)
        llSetTimerEvent(AUTO_CLOSE_TIME);
    }

    // We will close the object either if it's touched while fully open, or after a time
    touch_end(integer num) {
        state closing;
    }

    timer() {
        state closing;
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

// State for when the object is in the process of closing
state closing {
    state_entry() {
        startMove(Home);
    }

    timer() {
        endMove(Home);
        state default;
    }

    at_target(integer tnum, vector targetpos, vector ourpos) {
        if (tnum == TargetID) {
            removeTarget(targetpos, ourpos);
        }
    }

    not_at_target() {
        llOwnerSay("Not there yet - object is at " + (string)llGetPos());
    }
}
