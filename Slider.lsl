// Object Slider
//
// Written 05-October-2026 by Missy Restless <missyrestless@gmail.com>
// Based on sliding door script by by Omei Qunhua
//
// Ignore touches while sliding

vector     Home;                // Initial closed position
rotation   Rot;                 // Initial rotation of the object
vector     Offset;              // Populated with the move distance stored in the axis position
integer    AUTO_CLOSE_TIME = 0; // Can be zero if no auto-close is desired
integer    Phantom; 
integer    Physics; 

// Set the object PHANTOM and PHYSICAL and start moving it
startMove(vector Target) {
    // Do this first, to avoid the object dropping
    llMoveToTarget(Target, 3);

    llSetStatus(STATUS_PHANTOM, TRUE);
    llSetStatus(STATUS_PHYSICS, TRUE);

    // Start a timer. We will end the move after this time.
    llSetTimerEvent(6);
}

endMove(vector Target) {
    // Return the object to original phantom and physical states, do a final confirmatory move
    llSetTimerEvent(0);
    llSetStatus(STATUS_PHYSICS, Physics);
    llSetStatus(STATUS_PHANTOM, Phantom);
    llSetPrimitiveParams([ PRIM_POSITION, Target, PRIM_ROTATION, Rot ]);
}

default {
    state_entry() {
        vector Scale = llGetScale();
        Rot = llGetRot();
        Home = llGetPos();
        Phantom = llGetStatus(STATUS_PHANTOM);
        Physics = llGetStatus(STATUS_PHYSICS);

        // Find the middle sized dimension of the object
        // This determines the axis to move on, and the distance to move
        list lx = llListSort( [Scale.x, <1,0,0>, Scale.y, <0,1,0>, Scale.z, <0,0,1> ], 2, TRUE ); 
        // Apply the distance to move to the appropriate dimension
        Offset = llList2Vector(lx, 3) * llList2Float(lx, 2);
    }

    touch_end(integer total_number) {
        state opening;
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
}
