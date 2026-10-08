///////////////////// Slider \\\\\\\\\\\\\\\\\\\\\\\
//                                                //
//    Smooth Object Slide and Return on Touch     //
////////////////////////////////////////////////////
//
////////////////////////////////////////////////////
// Copyright (c) 2026 Truth & Beauty Lab          //
// License: MIT                                   //
// All rights reserved.                           //
//                                                //
// Author: Missy Restless missyrestless@gmail.com //
////////////////////////////////////////////////////
//
// 06-Oct-2026 Created by Missy Restless <missyrestless@gmail.com>
// 07-Oct-2026
//   - Add dialog menus
//   - Add linkset datastore support
//   - Customize slide axis and distance
// 07-Oct-2026
//   - Add debug and info menu entries
//   - Loop sound and stop sound when move complete

string    VERSION  = "1.0.3";

integer   Access   = 2;        // 0 = Owner, 1 = Group, 2 = Public
integer   Constant = TRUE;     // Whether to maintain a constant speed
integer   Debug    = FALSE;    // Set to TRUE for verbose debug output
integer   Enabled  = TRUE;     // Whether touch to slide is enabled
integer   Reverse  = FALSE;    // Reverse the orientation of movement
integer   Reset    = FALSE;    // Whether to perform a reset after moving
string    Axis     = "X";      // Axis on which to slide - X, Y, or Z
string    State;               // Track the state for dialog menu returns
float     Distance;            // How far to slide in meters
float     Duration = 4.0;      // How long to slide in seconds
float     Speed    = 1.0;      // How fast to slide in meters per second (Distance/Duration)
rotation  Rot;                 // Initial rotation of the object
vector    Home;                // Initial closed position
vector    Open;                // Open position

// Sounds
//
// Define a sound that plays when the object starts to open. If a sound
// file named "Open" is in the prim inventory then it will be used instead
string  SOUND_ON_OPEN  = "e5e01091-9c1f-4f8c-8486-46d560ff664f";
// Define a sound that plays when the object has closed. If a sound file
// named "Close" is in the prim inventory then it will be used instead
string  SOUND_ON_CLOSE = "88d13f1f-85a8-49da-99f7-6fa2781b2229";
// Define the volume of the opening and closing sounds
float   SOUND_VOLUME   = 1.0;

// Dialog Menus
integer dialogHandle;        // Dialog Menu listener handle
integer dialogChannel;       // Dialog Menu channel
integer inputChannel;        // Input text box channel
integer pageNumber     = 1;  // Dialog Menu page number
integer inputListen    = -1;
integer inDistanceMenu = FALSE;
integer inSpeedMenu    = FALSE;
float   LISTEN_TTL     = 60.0;                
key     Owner          = NULL_KEY;
key     Tcher          = NULL_KEY;
string  linksetValue;
string  menuMessage;

// Linkset Data Keys
//
// Access restrictions
string  ACCESS_LSD_KEY    = "access";
// Slide speed rate
string  CONSTANT_LSD_KEY  = "constant";
// Distance to slide
string  DIST_LSD_KEY      = "dist";
// Duration of the slide
string  DURATION_LSD_KEY  = "duration";
// Speed of the slide
string  SPEED_LSD_KEY     = "speed";
// Slide axis
string  AXIS_LSD_KEY      = "axis";
// Slide orientation
string  REVERSE_LSD_KEY   = "reverse";

moveToTarget(float dst) {
    if (Reverse) {
        dst = -dst;
    }
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
    list keyframe = [global_offset, ZERO_ROTATION, Duration];

    // Trigger the smooth motion
    if (Debug) {
        llOwnerSay("Calling llSetKeyframedMotion with keyframe = " + llDumpList2String(keyframe, ", "));
    }
    llSetKeyframedMotion(keyframe, []);
}

string getInfo(integer show) {
    // Retrieve current datastore values
    getDatastoreValues();

    string info  = "Truth & Beauty Slider version " + VERSION;
    string slurl = getSlurl();
    info += "\nLocation: \t" + slurl;
    info += "\nState:    \t";
    if (Enabled) {
        info += "ENABLED";
    } else {
        info += "DISABLED";
    }
    if (State == "open") {
        info += " and OPEN";
    } else {
        info += " and CLOSED";
    }
    info += "\nAccess:   \t";
    if (Access == 2) {
        info += "PUBLIC";
    } else if (Access == 1) {
        info += "GROUP";
    } else if (Access == 0) {
        info += "OWNER";
    } else {
        info += "UNKNOWN";
    }
    info += "\nRate:     \t";
    if (Constant) {
        info += "CONSTANT";
    } else {
        info += "VARIABLE";
    }
    info += "\nDistance: \t" + (string)Distance;
    info += "\nDuration: \t" + (string)Duration;
    info += "\nSpeed:    \t" + (string)Speed;
    info += "\nAxis:     \t" + Axis;
    info += "\nDirection:\t";
    if (Reverse) {
        info += "REVERSE";
    } else {
        info += "FORWARD";
    }
    info += "\nDebug:    \t";
    if (Debug) {
        info += "ON";
    } else {
        info += "OFF";
    }
    if (show) {
        llOwnerSay(info);
    }
    return info;
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
    inSpeedMenu    = FALSE;

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

displaySpeedMenu() {
    if (inputListen != -1) llListenRemove(inputListen);
    llListenRemove(dialogHandle);
    dialogHandle = llListen(dialogChannel, "", Tcher, "");
    list speed_menu = [];
    inSpeedMenu     = TRUE;
    inDistanceMenu  = FALSE;

    menuMessage = "\nTruth & Beauty Slider " + VERSION;
    menuMessage += "\nCurrent Slide Speed:\t" + (string)Speed;
    if (Constant) {
        menuMessage += "\nCurrent Slide Rate:\tCONSTANT";
    } else {
        menuMessage += "\nCurrent Slide Rate:\tVARIABLE";
    }
    if (Constant) {
        menuMessage += "\nVARIABLE = Increase speed with larger distance";
    } else {
        menuMessage += "\nCONSTANT = Maintain a constant speed regardless of distance";
    }
    menuMessage += "\nSelect a slide speed or ENTER to enter a custom value for speed";
    speed_menu += ["0.25 MPS", "0.5 MPS", "0.75 MPS"];
    speed_menu += ["1 MPS", "1.25 MPS", "1.5 MPS"];
    speed_menu += ["1.75 MPS", "2 MPS"];
    if (Constant) {
        speed_menu += ["ENTER", "VARIABLE", "MAIN MENU"];
    } else {
        speed_menu += ["ENTER", "CONSTANT", "MAIN MENU"];
    }
    speed_menu += ["2.25 MPS", "2.5 MPS", "2.75 MPS"];
    speed_menu += ["3 MPS", "3.5 MPS", "4 MPS"];
    speed_menu += ["4.5 MPS", "5 MPS", "5.5 MPS"];
    speed_menu += ["MAIN MENU"];
    speed_menu += ["6 MPS", "6.5 MPS", "7 MPS"];
    speed_menu += ["7.5 MPS", "8 MPS", "8.5 MPS"];
    speed_menu += ["9 MPS", "9.5 MPS", "10 MPS"];
    speed_menu += ["MAIN MENU"];
    speed_menu += ["11 MPS", "12 MPS", "13 MPS"];
    speed_menu += ["15 MPS", "18 MPS", "21 MPS"];
    speed_menu += ["25 MPS", "30 MPS", "35 MPS"];
    speed_menu += ["ENTER", "MAIN MENU"];
    ShowMenu(menuMessage, speed_menu);
}

displayMainMenu() {
    if (inputListen != -1) llListenRemove(inputListen);
    llListenRemove(dialogHandle);
    dialogHandle = llListen(dialogChannel, "", Tcher, "");
    list main_menu = [];
    inDistanceMenu = FALSE;
    inSpeedMenu    = FALSE;

    menuMessage = getInfo(FALSE);
    menuMessage += "\nCLEAR = Clear storage, reset to default values";
    menuMessage += "\nRESET = Reset scripts, storage persists\n";
    if (Access == 2) {
        main_menu += ["OWNER", "GROUP"];
    } else if (Access == 1) {
        main_menu += ["OWNER", "PUBLIC"];
    } else if (Access == 0) {
        main_menu += ["GROUP", "PUBLIC"];
    }
    if (Axis == "X") {
        main_menu += ["Y-AXIS", "Z-AXIS"];
    } else if (Axis == "Y") {
        main_menu += ["X-AXIS", "Z-AXIS"];
    } else if (Axis == "Z") {
        main_menu += ["X-AXIS", "Y-AXIS"];
    }
    main_menu += ["CLEAR", "RESET"];
    if (Reverse) {
        main_menu += ["FORWARD"];
    } else {
        main_menu += ["REVERSE"];
    }
    main_menu += ["SLIDE", "DISTANCE", "SPEED", "EXIT"];
    if (Enabled) {
        main_menu += ["DISABLE"];
    } else {
        main_menu += ["ENABLE"];
    }
    if (Debug) {
        main_menu += ["DEBUG OFF", "INFO", "EXIT"];
    } else {
        main_menu += ["DEBUG ON", "INFO", "EXIT"];
    }
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
    // Access restrictions
    linksetValue = llLinksetDataRead(ACCESS_LSD_KEY);
    if (linksetValue != "") {
        Access = (integer)linksetValue;
    }
    // Slide speed rate
    linksetValue = llLinksetDataRead(CONSTANT_LSD_KEY);
    if (linksetValue != "") {
        Constant = (integer)linksetValue;
    }
    // Distance to slide
    linksetValue = llLinksetDataRead(DIST_LSD_KEY);
    if (linksetValue != "") {
        Distance = (float)linksetValue;
    }
    // Duration of the slide
    linksetValue = llLinksetDataRead(DURATION_LSD_KEY);
    if (linksetValue != "") {
        Duration = (float)linksetValue;
    }
    // Speed of the slide
    linksetValue = llLinksetDataRead(SPEED_LSD_KEY);
    if (linksetValue != "") {
        Speed = (float)linksetValue;
    }
    // Slide axis
    linksetValue = llLinksetDataRead(AXIS_LSD_KEY);
    if (linksetValue != "") {
        Axis = linksetValue;
    }
    // Slide orientation
    linksetValue = llLinksetDataRead(REVERSE_LSD_KEY);
    if (linksetValue != "") {
        Reverse = (integer)linksetValue;
    }
}

setDatastoreValues(key id) {
    //
    // Set all configuration values stored in the linkset datastore
    //
    // Access restrictions
    linksetDataWrite(id, ACCESS_LSD_KEY, (string)Access, "Access restrictions");
    // Slide speed rate
    linksetDataWrite(id, CONSTANT_LSD_KEY, (string)Constant, "Slide speed rate");
    // Distance to slide
    linksetDataWrite(id, DIST_LSD_KEY, (string)Distance, "Distance to slide");
    // Duration of the slide
    linksetDataWrite(id, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
    // Speed of the slide
    linksetDataWrite(id, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
    // Slide axis
    linksetDataWrite(id, AXIS_LSD_KEY, Axis, "Slide axis");
    // Slide orientation
    linksetDataWrite(id, REVERSE_LSD_KEY, (string)Reverse, "Slide orientation");
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
    if (Reverse) {
        dist = -dist;
    }
    if (dir == "X") {
        Open = Home + <dist, 0.0, 0.0>;
    } else if (dir == "Y") {
        Open = Home + <0.0, dist, 0.0>;
    } else if (dir == "Z") {
        Open = Home + <0.0, 0.0, dist>;
    } else {
        Axis = "X";
        linksetDataWrite(Owner, AXIS_LSD_KEY, Axis, "Slide axis");
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
    // Clean up whitespace
    input = llStringTrim(input, STRING_TRIM);
    // Drop an optional leading "+" since casting to string removes it
    if (llGetSubString(input, 0, 0) == "+") {
        input = llGetSubString(input, 1, -1);
    }
    // Reject empty string early
    if (input == "") return FALSE;
    // Cast to float, then back to string, and compare
    float f = (float)input;
    if ((string)f == input) return TRUE;
    // Handle trailing zeros or missing decimal formats (e.g., "5" vs "5.000000")
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
        linksetDataWrite(Owner, AXIS_LSD_KEY, Axis, "Slide axis");
        Distance = Size.x;
    }
    // Default Speed is 1 mps
    Duration = Distance;
    Speed = 1.0;
    linksetDataWrite(Owner, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
    linksetDataWrite(Owner, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
}

default {
    state_entry() {
        Owner = llGetOwner();
        Tcher = NULL_KEY;
        Rot   = llGetRot();
        Home  = llGetPos();
        Reset = FALSE;
        State = "default";

        Distance = -9999.9;

        // Set the stored variable values
        getDatastoreValues();

        if (llGetInventoryType("Open") == INVENTORY_SOUND) {
            SOUND_ON_OPEN = "Open";
        }
        if (llGetInventoryType("Close") == INVENTORY_SOUND) {
            SOUND_ON_CLOSE = "Close";
        }

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
                llLoopSound(SOUND_ON_OPEN, SOUND_VOLUME);
            }
            if (SOUND_ON_CLOSE) {
                llPreloadSound(SOUND_ON_CLOSE);
            }
            if (Debug) {
                llOwnerSay("Calling moveToTarget(" + (string)Distance + ") in opening state");
            }
            moveToTarget(Distance);
            llSetTimerEvent(Duration);
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
        if (SOUND_ON_OPEN) {
            llLinkStopSound(LINK_THIS);
        }
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
                llLoopSound(SOUND_ON_CLOSE, SOUND_VOLUME);
            }
            if (SOUND_ON_OPEN) {
                llPreloadSound(SOUND_ON_OPEN);
            }
            if (Debug) {
                llOwnerSay("Calling moveToTarget(-" + (string)Distance + ") in closing state");
            }
            moveToTarget(-Distance);
            llSetTimerEvent(Duration);
        }
    }

    timer() {
        llSetTimerEvent(0);
        if (Reset) {
            Reset = FALSE;
            llResetScript();
        }
        state closed;
    }
}

// State for when the object is closed
state closed {
    state_entry() {
        State = "closed";
        if (SOUND_ON_CLOSE) {
            llLinkStopSound(LINK_THIS);
        }
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
            } else if (message == "SLIDE") {
                if (State == "default") {
                    state opening;
                } else if (State == "open") {
                    state closing;
                } else if (State == "closed") {
                    state opening;
                }
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
            } else if (message == "RESET") {
                if (State == "open") {
                    Reset = TRUE;
                    state closing;
                } else {
                    llResetScript();
                }
            } else if (message == "CONSTANT") {
                Constant = TRUE;
                linksetDataWrite(id, CONSTANT_LSD_KEY, (string)Constant, "Slide speed rate");
            } else if (message == "VARIABLE") {
                Constant = FALSE;
                linksetDataWrite(id, CONSTANT_LSD_KEY, (string)Constant, "Slide speed rate");
            } else if (message == "DISTANCE") {
                displayDistanceMenu();
                return;
            } else if (message == "DEBUG OFF") {
                Debug = FALSE;
            } else if (message == "DEBUG ON") {
                Debug = TRUE;
            } else if (message == "INFO") {
                getInfo(TRUE);
            } else if (message == "FORWARD") {
                Reverse = FALSE;
                setOpenPos(Axis, Distance);
                linksetDataWrite(id, REVERSE_LSD_KEY, (string)Reverse, "Slide orientation");
            } else if (message == "REVERSE") {
                Reverse = TRUE;
                setOpenPos(Axis, Distance);
                linksetDataWrite(id, REVERSE_LSD_KEY, (string)Reverse, "Slide orientation");
            } else if (message == "SPEED") {
                displaySpeedMenu();
                return;
            } else if (message == "OWNER") {
                if (id == Owner) {
                    Access = 0;
                    linksetDataWrite(id, ACCESS_LSD_KEY, (string)Access, "Access restrictions");
                } else {
                    if (id) llRegionSayTo(id, 0, "Only the owner can set the access privilages");
                }
            } else if (message == "GROUP") {
                if (id == Owner) {
                    Access = 1;
                    linksetDataWrite(id, ACCESS_LSD_KEY, (string)Access, "Access restrictions");
                } else {
                    if (id) llRegionSayTo(id, 0, "Only the owner can set the access privilages");
                }
            } else if (message == "PUBLIC") {
                if (id == Owner) {
                    Access = 2;
                    linksetDataWrite(id, ACCESS_LSD_KEY, (string)Access, "Access restrictions");
                } else {
                    if (id) llRegionSayTo(id, 0, "Only the owner can set the access privilages");
                }
            } else if (message == "ENTER") {
                if (inputListen != -1) llListenRemove(inputListen);
                inputListen = llListen(inputChannel, "", id, "");
                llSetTimerEvent(LISTEN_TTL);
                if (inDistanceMenu) {
                    llTextBox(id, "\nEnter the desired slide distance into the box)", inputChannel);
                } else if (inSpeedMenu) {
                    llTextBox(id, "\nEnter the desired slide speed into the box)", inputChannel);
                } else {
                    displayMainMenu();
                }
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
                if (Constant) {
                    Duration = Distance / Speed;
                    linksetDataWrite(Owner, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
                } else {
                    Speed = Distance / Duration;
                    linksetDataWrite(Owner, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
                }
                linksetDataWrite(id, DIST_LSD_KEY, dst, "Distance to slide");
                setOpenPos(Axis, Distance);
            } else if (llGetSubString(message, -4, -1) == " MPS") {
                string vel = llDeleteSubString(message, -4, -1);
                Speed = (float)vel;
                linksetDataWrite(Owner, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
                if (Constant) {
                    Duration = Distance / Speed;
                    linksetDataWrite(Owner, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
                }
            }
            // Re-send the dialog to keep the menu open
            if (inDistanceMenu) {
                displayDistanceMenu();
            } else if (inSpeedMenu) {
                displaySpeedMenu();
            } else {
                displayMainMenu();
            }
        } else if (channel == inputChannel) {
            string valu = llStringTrim(message, STRING_TRIM);
            if (isFloat(valu)) {
                if (inDistanceMenu) {
                    Distance = (float)valu;
                    if (Constant) {
                        Duration = Distance / Speed;
                        linksetDataWrite(Owner, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
                    } else {
                        Speed = Distance / Duration;
                        linksetDataWrite(Owner, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
                    }
                    linksetDataWrite(id, DIST_LSD_KEY, valu, "Distance to slide");
                    setOpenPos(Axis, Distance);
                } else if (inSpeedMenu) {
                    Speed = (float)valu;
                    linksetDataWrite(Owner, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
                    if (Constant) {
                        Duration = Distance / Speed;
                        linksetDataWrite(Owner, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
                    }
                }
            } else {
                llRegionSayTo(id, 0, "[Slider] " + valu + " is not a valid number.");
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
            if (State == "open") {
                moveToTarget(-Distance);
            }
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
