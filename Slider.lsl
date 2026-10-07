// Smooth Object Slide on touch using llSetKeyframedMotion (KFM)
//
// 06-Oct-2026 Created by Missy Restless <missyrestless@gmail.com>
// 07-Oct-2026
//   - Add dialog menus
//   - Add linkset datastore support
//   - Customize slide axis and distance

string  VERSION = "1.0.2";

integer   Access  = 2;         // 0 = Owner, 1 = Group, 2 = Public
integer   Debug   = FALSE;     // Set to TRUE for verbose debug output
integer   Enabled = TRUE;      // Whether touch to slide is enabled
string    Axis    = "X";       // Axis on which to slide - X, Y, or Z
string    State;               // Track the state for dialog menu returns
float     Distance;            // How far to slide
rotation  Rot;                 // Initial rotation of the object
vector    Home;                // Initial closed position
vector    Open;                // Open position

// Sounds
//
// Define a sound that plays when the door starts to open; set to NULL_KEY for no sound.
key     SOUND_ON_OPEN  = "e5e01091-9c1f-4f8c-8486-46d560ff664f";
// Define a sound that plays when the door has closed; set to NULL_KEY for no sound.
key     SOUND_ON_CLOSE = "88d13f1f-85a8-49da-99f7-6fa2781b2229";
// Define the volume of the opening and closing sounds
float   SOUND_VOLUME   = 1.0;

// Dialog Menus
integer dialogHandle;        // Dialog Menu listener handle
integer dialogChannel;       // Dialog Menu channel
integer inputChannel;        // Input text box channel
integer pageNumber     = 1;  // Dialog Menu page number
integer inputListen    = -1;
integer inDistanceMenu = FALSE;
float   LISTEN_TTL     = 60.0;                
key     Owner          = NULL_KEY;
key     Tcher          = NULL_KEY;
string  linksetValue;
string  menuMessage;

// Linkset Data Keys
//
// Distance to slide
string  DIST_LSD_KEY      = "dist";
// Slide axis
string  AXIS_LSD_KEY      = "axis";

moveToTarget(float dst) {
    if (Debug) {
        llOwnerSay("In moveToTarget(dst) with dst = " + (string)dst);
    }
    // Calculate the local translation vector
    vector local_offset;
    if (Axis == "X") {
        local_offset = <dst, 0.0, 0.0>;
    } else if (Axis == "Y") {
        local_offset = <0.0, dst, 0.0>;
    } else if (Axis == "Z") {
        local_offset = <0.0, 0.0, dst>;
    } else {
        Axis = "X";
        local_offset = <dst, 0.0, 0.0>;
    }
        
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

list arrange(list l) {
    list outl = [];
    integer n = llGetListLength(l);
    do {
        if (n < 3) return outl + l;
        n = n - 3;
        outl = outl + llList2List(l, -3, -1);
        if (n == 0) return outl;
        l = llList2List(l, 0, -4);
    } while (TRUE);
    return [];
}

displayDistanceMenu() {
    if (inputListen != -1) llListenRemove(inputListen);
    llListenRemove(dialogHandle);
    dialogHandle = llListen(dialogChannel, "", Tcher, "");
    list dist_menu = [];

    inDistanceMenu = TRUE;
    menuMessage = "\nTruth & Beauty Slider " + VERSION;
    menuMessage += "\nCurrent Slide Distance:\t" + (string)Distance;
    menuMessage += "\nSelect a slide distance or ENTER to enter a custom value for distance";
    dist_menu += ["0.25 M", "0.5 M", "0.75 M"];
    dist_menu += ["1 M", "2 M", "3 M"];
    dist_menu += ["4 M", "5 M", "6 M"];
    dist_menu += ["ENTER", "MAIN MENU"];
    dist_menu += ["7 M", "8 M", "9 M"];
    dist_menu += ["10 M", "11 M", "12 M"];
    dist_menu += ["13 M", "14 M", "15 M"];
    dist_menu += ["MAIN MENU"];
    dist_menu += ["16 M", "17 M", "18 M"];
    dist_menu += ["19 M", "20 M", "21 M"];
    dist_menu += ["22 M", "23 M", "24 M"];
    dist_menu += ["MAIN MENU"];
    dist_menu += ["25 M", "26 M", "27 M"];
    dist_menu += ["28 M", "29 M", "30 M"];
    dist_menu += ["31 M", "32 M", "33 M"];
    dist_menu += ["ENTER", "MAIN MENU"];
    ShowMenu(menuMessage, dist_menu);
}

displayMainMenu() {
    if (inputListen != -1) llListenRemove(inputListen);
    llListenRemove(dialogHandle);
    dialogHandle = llListen(dialogChannel, "", Tcher, "");
    list main_menu = [];

    inDistanceMenu = FALSE;
    menuMessage = "\nTruth & Beauty Slider " + VERSION;
    menuMessage += "\nCLEAR = Clear storage, reset to default values";
    if (Enabled) {
        menuMessage += "\nTouch to Slide:\tEnabled";
        main_menu = ["DISABLE"];
    } else {
        menuMessage += "\nTouch to Slide:\tDisabled";
        main_menu = ["ENABLE"];
    }
    menuMessage += "\nSlide Axis:\t" + Axis;
    if (Access == 2) {
        menuMessage += "\nAccess:\tPublic";
        main_menu += ["OWNER", "GROUP"];
    } else if (Access == 1) {
        menuMessage += "\nAccess:\tGroup";
        main_menu += ["OWNER", "PUBLIC"];
    } else if (Access == 0) {
        menuMessage += "\nAccess:\tOwner";
        main_menu += ["GROUP", "PUBLIC"];
    }
    if (Axis == "X") {
        main_menu += ["Y-AXIS", "Z-AXIS"];
    } else if (Axis == "Y") {
        main_menu += ["X-AXIS", "Z-AXIS"];
    } else if (Axis == "Z") {
        main_menu += ["X-AXIS", "Y-AXIS"];
    }
    if (State == "default") {
        main_menu += ["OPEN"];
    } else if (State == "open") {
        main_menu += ["CLOSE"];
    } else if (State == "closed") {
        main_menu += ["OPEN"];
    }
    main_menu += ["CLEAR", "DISTANCE", "EXIT"];
    ShowMenu(menuMessage, main_menu);
}

// Show the specific menu page
// Pass in the full menu list
ShowMenu(string msg, list fm) {
    integer list_length = llGetListLength(fm);
    if (list_length > 12) {
        integer totalPages = (list_length / 10) + (list_length % 10 != 0);

        // Safety check: bound page numbers
        if (pageNumber < 1) pageNumber = 1;
        if (pageNumber > totalPages) pageNumber = totalPages;

        integer nump = 12;
        if (pageNumber > 1) nump--;
        if (pageNumber < totalPages) nump--;

        // Calculate slice indices
        integer start = (pageNumber - 1) * nump;
        integer end = start + (nump -1);

        // Grab the 10 (or fewer) items for this page
        list displayList = llList2List(fm, start, end);

        // Add navigation buttons to the bottom of the list
        if (totalPages > 1) {
            if (pageNumber > 1) displayList += ["<<< Prev"];
            if (pageNumber < totalPages) displayList += ["Next >>>"];
        }

        // Send the dialog page
        llDialog(Tcher, msg + " (Page " + (string)pageNumber + " of " +
                (string)totalPages + "):", arrange(displayList), dialogChannel);
    } else {
        // Send the dialog
        llDialog(Tcher, msg, arrange(fm), dialogChannel);
    }
    llSetTimerEvent(120);   // If no response in time, return to previous state
}

getDatastoreValues() {
    //
    // Retrieve any configuration values stored in the linkset datastore
    //
    // Distance to slide
    linksetValue = llLinksetDataRead(DIST_LSD_KEY);
    if (linksetValue != "") {
        Distance = (float)linksetValue;
    }
    // Slide axis
    linksetValue = llLinksetDataRead(AXIS_LSD_KEY);
    if (linksetValue != "") {
        Axis = linksetValue;
    }
}

setDatastoreValues(key id) {
    //
    // Set all configuration values stored in the linkset datastore
    //
    // Distance to slide
    linksetDataWrite(id, DIST_LSD_KEY, (string)Distance, "Distance to slide");
    // Slide axis
    linksetDataWrite(id, AXIS_LSD_KEY, Axis, "Slide axis");
}

// Writes the provided key/value pair to the prim's linkset datastore
integer linksetDataWrite(key id, string lsdKey, string value, string cfg) {
    string val = llStringTrim(value, STRING_TRIM);
    integer returnCode = llLinksetDataWrite(lsdKey, val);
    if (returnCode == LINKSETDATA_OK) {
        if (id) {
            llRegionSayTo(id, 0, "[Slider] " + cfg + " saved.");
        }
    } else if (returnCode != LINKSETDATA_NOUPDATE) {
        if (id) {
            llRegionSayTo(id, 0, "[Slider] " + cfg + " save failed (code " + (string)returnCode + ").");
        }
    }
    return returnCode;
}

setOpenPos(string dir, float dist) {
    if (dir == "X") {
        Open = Home + <dist, 0.0, 0.0>;
    } else if (dir == "Y") {
        Open = Home + <0.0, dist, 0.0>;
    } else if (dir == "Z") {
        Open = Home + <0.0, 0.0, dist>;
    } else {
        Axis = "X";
        Open = Home + <dist, 0.0, 0.0>;
    }
}

string getSlurl() {
    vector currentPos = llGetPos();
    string regionName = llGetRegionName();

    // Round coordinates to whole integers
    integer x = (integer)currentPos.x;
    integer y = (integer)currentPos.y;
    integer z = (integer)currentPos.z;
    string coords = (string)x + "/" + (string)y + "/" + (string)z;

    // Return the constructed Slurl, escape region name as it may have spaces
    return "https://maps.secondlife.com/secondlife/" + llEscapeURL(regionName) + "/" + coords;
}

integer isFloat(string input) {
    // 1. Clean up whitespace
    input = llStringTrim(input, STRING_TRIM);
    // 2. Drop an optional leading "+" since casting to string removes it
    if (llGetSubString(input, 0, 0) == "+") {
        input = llGetSubString(input, 1, -1);
    }
    // 3. Reject empty string early
    if (input == "") return FALSE;
    // 4. Cast to float, then back to string, and compare
    float f = (float)input;
    if ((string)f == input) return TRUE;
    // 5. Handle trailing zeros or missing decimal formats (e.g., "5" vs "5.000000")
    // If the input represents the exact same float value, it's valid
    if ((float)((string)f) == (float)input) {
        // Prevent false positives on completely invalid text (which LSL casts to 0.0)
        if (f == 0.0) {
            // Ensure the input actually meant zero (like "0", "0.0", "-0")
            return (llGetSubString((string)((integer)input), 0, 0) == "0" || input == "0." || input == ".0");
        }
        return TRUE;
    }
    return FALSE;
}

setDefaults() {
    // Get the object's size (length)
    vector Size = llGetScale();
    if (Axis == "X") {
        Distance = Size.x;
    } else if (Axis == "Y") {
        Distance = Size.y;
    } else if (Axis == "Z") {
        Distance = Size.z;
    } else {
        Axis = "X";
        Distance = Size.x;
    }
}

default {
    state_entry() {
        Owner = llGetOwner();
        Tcher = NULL_KEY;
        Rot   = llGetRot();
        Home  = llGetPos();
        State = "default";

        Distance = -9999.9;

        // Set the stored variable values
        getDatastoreValues();

        if (SOUND_ON_OPEN) {
            llPreloadSound(SOUND_ON_OPEN);
        }

        // Set the object physics shape to Convex Hull and Disable physics
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
            PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_CONVEX,
            PRIM_PHYSICS, FALSE
        ]);
        // Define the distance to move (using the X dimension of its size)
        if (Distance == -9999.9) {
            setDefaults();
        }
        setOpenPos(Axis, Distance);
        // Set open position
        if (Debug) {
            llOwnerSay("Distance = " + (string)Distance);
            llOwnerSay("Home     = " + (string)Home);
            llOwnerSay("Open     = " + (string)Open);
        }

        setDatastoreValues(Owner);

        // Compute a negative communications channel based on prim UUID
        dialogChannel   = 0x80000000 | (integer) ( "0x" + (string) llGetKey() );
        inputChannel    = (integer)(llFrand(-1000000000.0) - 1000000000.0);
    }

    touch_start(integer num_detected) {
        Tcher = llDetectedKey(0);
        // Ensure only the owner or group members triggers the timer start check
        if (Access == 2) {
            // In Public mode only the owner and group members have access to the menu
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                llResetTime(); // Starts tracking duration
            } else {
                state opening;
            }
        } else if (Access == 1) {
            // In Group mode only the owner and group members have access
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                llResetTime(); // Starts tracking duration
            } else {
                Tcher = NULL_KEY;
            }
        } else if (Access == 0) {
            // In Owner mode only the owner has access
            if (Tcher == Owner) {
                llResetTime(); // Starts tracking duration
            } else {
                Tcher = NULL_KEY;
            }
        }
    }

    touch_end(integer num_detected) {
        float holdTime = llGetTime();
        if (Access == 2) {
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    state opening;
                }
            } else {
                state opening;
            }
        } else if (Access == 1) {
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    state opening;
                }
            }
        } else if (Access == 0) {
            if (Tcher == Owner) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    state opening;
                }
            }
        }
    }

    on_rez(integer num) {
        Owner = llGetOwner();
        string slurl = getSlurl();
        llOwnerSay("The Truth & Beauty Slider located at " + slurl + " is now active.");
        llOwnerSay("Touch to slide open and close. Long touch to open the menu.");
        llOwnerSay("Slider updates are free for life and will be available at:");
        llOwnerSay("    https://github.com/missyrestless/Slider/releases");
        llOwnerSay("The latest Truth & Beauty Slider documentation can be found at:");
        llOwnerSay("    https://github.com/missyrestless/Slider#readme");
        llResetScript();
    }

    changed(integer change) {
        // Check if the change event was caused by an owner change
        if (change & CHANGED_OWNER) {
            // Reset/wipe all key-value pairs in the linkset data store
            llLinksetDataReset();
            llResetScript();
        } else if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

// In this state, the object is in process of sliding open
// Ignore touches while sliding
state opening {
    state_entry() {
        if (Enabled) {
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
    }

    timer() {
        llSetTimerEvent(0);
        state open;
    }
}

// State for when the object is fully open
state open {
    state_entry() {
        State = "open";
        // Finalize move to open position
        if (Debug) {
            llOwnerSay("Finalize move to open position with call to:\nllSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_POSITION, " + (string)Open + ", PRIM_ROTATION, " + (string)Rot + "])");
        }
        llSetLinkPrimitiveParamsFast(LINK_ROOT, [
            PRIM_POSITION, Open,
            PRIM_ROTATION, Rot
        ]);
    }

    touch_start(integer num_detected) {
        Tcher = llDetectedKey(0);
        // Ensure only the owner or group members triggers the timer start check
        if (Access == 2) {
            // In Public mode only the owner and group members have access to the menu
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                llResetTime(); // Starts tracking duration
            } else {
                state closing;
            }
        } else if (Access == 1) {
            // In Group mode only the owner and group members have access
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                llResetTime(); // Starts tracking duration
            } else {
                Tcher = NULL_KEY;
            }
        } else if (Access == 0) {
            // In Owner mode only the owner has access
            if (Tcher == Owner) {
                llResetTime(); // Starts tracking duration
            } else {
                Tcher = NULL_KEY;
            }
        }
    }

    touch_end(integer num_detected) {
        float holdTime = llGetTime();
        if (Access == 2) {
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    state closing;
                }
            } else {
                state closing;
            }
        } else if (Access == 1) {
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    state closing;
                }
            }
        } else if (Access == 0) {
            if (Tcher == Owner) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    state closing;
                }
            }
        }
    }

    changed(integer change) {
        // Check if the change event was caused by an owner change
        if (change & CHANGED_OWNER) {
            // Reset/wipe all key-value pairs in the linkset data store
            llLinksetDataReset();
            llResetScript();
        } else if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

// State for when the object is in the process of sliding close
// Ignore touches while sliding
state closing {
    state_entry() {
        if (Enabled) {
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
    }

    timer() {
        llSetTimerEvent(0);
        state closed;
    }
}

// State for when the object is closed
state closed {
    state_entry() {
        State = "closed";
        // Finalize move to closed position
        if (Debug) {
            llOwnerSay("Finalize move to closed position with call to:\nllSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_POSITION, " + (string)Home + ", PRIM_ROTATION, " + (string)Rot + "])");
        }
        llSetLinkPrimitiveParamsFast(LINK_ROOT, [
            PRIM_POSITION, Home,
            PRIM_ROTATION, Rot
        ]);
    }

    touch_start(integer num_detected) {
        Tcher = llDetectedKey(0);
        // Ensure only the owner or group members triggers the timer start check
        if (Access == 2) {
            // In Public mode only the owner and group members have access to the menu
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                llResetTime(); // Starts tracking duration
            } else {
                state opening;
            }
        } else if (Access == 1) {
            // In Group mode only the owner and group members have access
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                llResetTime(); // Starts tracking duration
            } else {
                Tcher = NULL_KEY;
            }
        } else if (Access == 0) {
            // In Owner mode only the owner has access
            if (Tcher == Owner) {
                llResetTime(); // Starts tracking duration
            } else {
                Tcher = NULL_KEY;
            }
        }
    }

    touch_end(integer num_detected) {
        float holdTime = llGetTime();
        if (Access == 2) {
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    state opening;
                }
            } else {
                state opening;
            }
        } else if (Access == 1) {
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    state opening;
                }
            }
        } else if (Access == 0) {
            if (Tcher == Owner) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    state opening;
                }
            }
        }
    }

    changed(integer change) {
        // Check if the change event was caused by an owner change
        if (change & CHANGED_OWNER) {
            // Reset/wipe all key-value pairs in the linkset data store
            llLinksetDataReset();
            llResetScript();
        } else if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

state menu {
    state_entry() {
        displayMainMenu();
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == dialogChannel) {
            if (message == "DISABLE") {
                Enabled = FALSE;
            } else if (message == "ENABLE") {
                Enabled = TRUE;
            } else if (message == "OPEN") {
                state opening;
            } else if (message == "CLOSE") {
                state closing;
            } else if (message == "X-AXIS") {
                Axis = "X";
                setOpenPos(Axis, Distance);
                linksetDataWrite(id, AXIS_LSD_KEY, Axis, "Slide axis");
            } else if (message == "Y-AXIS") {
                Axis = "Y";
                setOpenPos(Axis, Distance);
                linksetDataWrite(id, AXIS_LSD_KEY, Axis, "Slide axis");
            } else if (message == "Z-AXIS") {
                Axis = "Z";
                setOpenPos(Axis, Distance);
                linksetDataWrite(id, AXIS_LSD_KEY, Axis, "Slide axis");
            } else if (message == "CLEAR") {
                state confirm;
            } else if (message == "DISTANCE") {
                displayDistanceMenu();
                return;
            } else if (message == "OWNER") {
                if (id == Owner) {
                    Access = 0;
                } else {
                    if (id) llRegionSayTo(id, 0, "Only the owner can set the access privilages");
                }
            } else if (message == "GROUP") {
                if (id == Owner) {
                    Access = 1;
                } else {
                    if (id) llRegionSayTo(id, 0, "Only the owner can set the access privilages");
                }
            } else if (message == "PUBLIC") {
                if (id == Owner) {
                    Access = 2;
                } else {
                    if (id) llRegionSayTo(id, 0, "Only the owner can set the access privilages");
                }
            } else if (message == "ENTER") {
                if (inputListen != -1) llListenRemove(inputListen);
                inputListen = llListen(inputChannel, "", id, "");
                llSetTimerEvent(LISTEN_TTL);
                llTextBox(id, "\nEnter the desired slide distance into the box)", inputChannel);
                return; // Exit the listen event
            } else if (message == "MAIN MENU") {
                displayMainMenu();
            } else if (message == "EXIT") {
                // Return to the currently active state
                if (State == "default") {
                    state default;
                } else if (State == "open") {
                    state open;
                } else if (State == "closed") {
                    state closed;
                } else {
                    state default;
                }
            } else if (message == "<<< Prev") {
                pageNumber--;
            } else if (message == "Next >>>") {
                pageNumber++;
            } else if (llGetSubString(message, -2, -1) == " M") {
                string dst = llDeleteSubString(message, -2, -1);
                Distance = (float)dst;
                linksetDataWrite(id, DIST_LSD_KEY, dst, "Distance to slide");
                setOpenPos(Axis, Distance);
            }
            // Re-send the dialog to keep the menu open
            if (inDistanceMenu) {
                displayDistanceMenu();
            } else {
                displayMainMenu();
            }
        } else if (channel == inputChannel) {
            string dist = llStringTrim(message, STRING_TRIM);
            if (isFloat(dist)) {
                Distance = (float)dist;
                linksetDataWrite(id, DIST_LSD_KEY, dist, "Distance to slide");
                setOpenPos(Axis, Distance);
            } else {
                llRegionSayTo(id, 0, "[Slider] " + dist + " is not a valid number.");
            }

            if (inputListen != -1) {
                llListenRemove(inputListen);
                inputListen = -1;
            }
        }
    }

    timer() {
        // Return to the currently active state
        if (State == "default") {
            state default;
        } else if (State == "open") {
            state open;
        } else if (State == "closed") {
            state closed;
        } else {
            state default;
        }
    }

    state_exit() {
        setDatastoreValues(Tcher);
        llSetTimerEvent(0);
    }
}

state confirm {
    state_entry() {
        llListenRemove(inputListen);
        inputListen = llListen(inputChannel, "", Owner, "");
        llSetTimerEvent(LISTEN_TTL);

        string msg = "This will clear all customized settings from storage, reset to default values, and restore to original position";
        msg += "\nAre you sure you want to proceed?";
        llDialog(Owner, msg, ["YES", "NO"], inputChannel);
    }

    listen(integer channel, string name, key id, string message) {
        llListenRemove(inputListen);
        inputListen = -1;
        if (message == "YES") {
            llLinksetDataReset();
            llSetLinkPrimitiveParamsFast(LINK_ROOT, [
                PRIM_POSITION, Home,
                PRIM_ROTATION, Rot
            ]);
            Axis = "X";
            setDefaults();
            setDatastoreValues(id);
            state default;
        } else if (message == "NO") {
            if (Debug) llOwnerSay("Clear linkset storage action cancelled.");
        }
        state menu;
    }

    timer() {
        llListenRemove(inputListen);
        inputListen = -1;
        llSetTimerEvent(0.0);
        state menu;
    }
}
