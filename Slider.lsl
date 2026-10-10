////////////////// Smooth Slider \\\\\\\\\\\\\\\\\\\
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

string    VERSION  = "1.1.0";

integer   Access   = 2;        // 0 = Owner, 1 = Group, 2 = Public
integer   Constant = TRUE;     // Whether to maintain a constant speed
integer   Debug    = FALSE;    // Set to TRUE for verbose debug output
integer   Enabled  = TRUE;     // Whether touch to slide is enabled
integer   Multi    = FALSE;    // Whether multi-dimension slide is enabled
integer   xReverse = FALSE;    // Reverse the orientation of movement along the X axis
integer   yReverse = FALSE;    // Reverse the orientation of movement along the Y axis
integer   zReverse = FALSE;    // Reverse the orientation of movement along the Z axis
string    Axis     = "X";      // Axis on which to slide - X, Y, Z, XY, XZ, YZ, or XYZ
string    State;               // Track the state for dialog menu returns
float     Duration = 4.0;      // How long to slide in seconds
float     Speed    = 1.0;      // How fast to slide in meters per second (Distance/Duration)
rotation  Rot;                 // Initial rotation of the object
vector    Home;                // Initial closed position
vector    Open;                // Open position
vector    Distance;            // How far to slide along the X axis

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
integer inDirectMenu   = FALSE;
integer inDistanceMenu = FALSE;
integer inSpeedMenu    = FALSE;
integer SetX           = FALSE;
integer SetY           = FALSE;
integer SetZ           = FALSE;
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
string  X_DIST_LSD_KEY    = "xdist";
string  Y_DIST_LSD_KEY    = "ydist";
string  Z_DIST_LSD_KEY    = "zdist";
// Duration of the slide
string  DURATION_LSD_KEY  = "duration";
// Speed of the slide
string  SPEED_LSD_KEY     = "speed";
// Slide axis
string  AXIS_LSD_KEY      = "axis";
// Slide orientation
string  X_REVERSE_LSD_KEY = "xreverse";
string  Y_REVERSE_LSD_KEY = "yreverse";
string  Z_REVERSE_LSD_KEY = "zreverse";

moveToTarget(vector dst) {
    if (xReverse) {
        dst.x = -dst.x;
    }
    if (yReverse) {
        dst.y = -dst.y;
    }
    if (zReverse) {
        dst.z = -dst.z;
    }
    if (Debug) {
        llOwnerSay("In moveToTarget(dst) with vector = " + (string)dst);
    }
    // Calculate the local translation vector
    vector local_offset;
    local_offset = <dst.x, dst.y, dst.z>;
        
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

    string info  = "Truth & Beauty Smooth Slider " + VERSION + "\n";
    string slurl = getSlurl();
    info += "\nLocation:\t" + slurl;
    info += "\nState:     \t";
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
    info += "\nAccess:    \t";
    if (Access == 2) {
        info += "PUBLIC";
    } else if (Access == 1) {
        info += "GROUP";
    } else if (Access == 0) {
        info += "OWNER";
    } else {
        info += "UNKNOWN";
    }
    info += "\nRate:       \t";
    if (Constant) {
        info += "CONSTANT";
    } else {
        info += "VARIABLE";
    }
    setAxis();
    info += "\nDistance: \t" + (string)Distance;
    info += "\nDuration: \t" + (string)Duration;
    info += "\nSpeed:     \t" + (string)Speed;
    info += "\nAxis:         \t" + Axis;
    info += "\nDirection:\t<";
    if (contains(Axis, "X")) {
        if (xReverse) {
            info += "MINUS, ";
        } else {
            info += "PLUS, ";
        }
    } else {
        info += "────, ";
    }
    if (contains(Axis, "Y")) {
        if (yReverse) {
            info += "MINUS, ";
        } else {
            info += "PLUS, ";
        }
    } else {
        info += "────, ";
    }
    if (contains(Axis, "Z")) {
        if (zReverse) {
            info += "MINUS>";
        } else {
            info += "PLUS>";
        }
    } else {
        info += "────>";
    }
    info += "\nDebug:     \t";
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

integer contains(string haystack, string needle) {
    return ~llSubStringIndex(haystack, needle);
}

setSets(string axis) {
    if (axis == "X") {
        SetX = TRUE;
        SetY = FALSE;
        SetZ = FALSE;
    } else if (axis == "Y") {
        SetX = FALSE;
        SetY = TRUE;
        SetZ = FALSE;
    } else if (axis == "Z") {
        SetX = FALSE;
        SetY = FALSE;
        SetZ = TRUE;
    }
}

displayDirectionMenu() {
    llListenRemove(dialogHandle);
    dialogHandle   = llListen(dialogChannel, "", Tcher, "");
    list dir_menu  = [];
    inDirectMenu   = TRUE;
    inDistanceMenu = FALSE;
    inSpeedMenu    = FALSE;

    menuMessage = "\nTruth & Beauty Smooth Slider " + VERSION;
    if (Multi) {
        menuMessage += "\nCurrent Slide Directions:\t X = ";
        if (xReverse) {
            menuMessage += (string)-Distance.x;
        } else {
            menuMessage += (string)Distance.x;
        }
        menuMessage += ", Y = ";
        if (yReverse) {
            menuMessage += (string)-Distance.x;
        } else {
            menuMessage += (string)Distance.x;
        }
        menuMessage += ", Z = ";
        if (zReverse) {
            menuMessage += (string)-Distance.x;
        } else {
            menuMessage += (string)Distance.x;
        }
        menuMessage += "\nSet the direction of each Axis";
        if (xReverse) {
            dir_menu += ["X FORWARD"];
        } else {
            dir_menu += ["X REVERSE"];
        }
        if (yReverse) {
            dir_menu += ["Y FORWARD"];
        } else {
            dir_menu += ["Y REVERSE"];
        }
        if (zReverse) {
            dir_menu += ["Z FORWARD"];
        } else {
            dir_menu += ["Z REVERSE"];
        }
    } else {
        menuMessage += "\nCurrent Slide Direction:\t";
        if (xReverse || yReverse || zReverse) {
            menuMessage += "REVERSE";
        } else {
            menuMessage += "FORWARD";
        }
        menuMessage += "\nCurrent Slide Axis:\t" + Axis;
        menuMessage += "\n\nSet the Direction and Axis of slide";
        dir_menu += ["X", "Y", "Z"];
        if (xReverse || yReverse || zReverse) {
            dir_menu += ["FORWARD"];
        } else {
            dir_menu += ["REVERSE"];
        }
    }
    dir_menu += ["DISTANCE", "MAIN MENU", "EXIT"];
    ShowMenu(menuMessage, dir_menu);
}

displayDistanceMenu() {
    if (inputListen != -1) llListenRemove(inputListen);
    llListenRemove(dialogHandle);
    dialogHandle = llListen(dialogChannel, "", Tcher, "");
    list dist_menu = [];
    inDistanceMenu = TRUE;
    inDirectMenu   = FALSE;
    inSpeedMenu    = FALSE;

    menuMessage = "\nTruth & Beauty Smooth Slider " + VERSION;
    menuMessage += "\nCurrent Slide Distance:\t" + (string)Distance;
    if (SetX || SetY || SetZ) {
        if (SetX) {
            menuMessage += "\nSelect the X-Axis slide distance or ENTER to enter a custom value";
        } else if (SetY) {
            menuMessage += "\nSelect the Y-Axis slide distance or ENTER to enter a custom value";
        } else if (SetZ) {
            menuMessage += "\nSelect the Z-Axis slide distance or ENTER to enter a custom value";
        }
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
    } else {
        menuMessage += "\nSelect an Axis on which to set the distance";
        dist_menu += ["X-AXIS", "Y-AXIS", "Z-AXIS"];
        dist_menu += ["DIRECTION", "MAIN MENU", "EXIT"];
    }
    ShowMenu(menuMessage, dist_menu);
}

displaySpeedMenu() {
    if (inputListen != -1) llListenRemove(inputListen);
    llListenRemove(dialogHandle);
    dialogHandle = llListen(dialogChannel, "", Tcher, "");
    list speed_menu = [];
    inSpeedMenu     = TRUE;
    inDistanceMenu  = FALSE;
    inDirectMenu    = FALSE;

    menuMessage = "\nTruth & Beauty Smooth Slider " + VERSION;
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
    inDirectMenu   = FALSE;

    menuMessage = getInfo(FALSE);
    menuMessage += "\n\nCLEAR = Clear storage, reset to default values";
    if (Multi) {
        menuMessage += "\nSINGLE = Slide along a single axis";
    } else {
        menuMessage += "\nMULTI  = Slide along multiple axes";
    }
    menuMessage += "\nRESET = Reset scripts, storage persists";
    if (!Enabled) {
        main_menu += ["ENABLE"];
    }
    if (Access == 2) {
        main_menu += ["OWNER", "GROUP"];
    } else if (Access == 1) {
        main_menu += ["OWNER", "PUBLIC"];
    } else if (Access == 0) {
        main_menu += ["GROUP", "PUBLIC"];
    }
    if (Multi) {
        main_menu += ["SINGLE"];
    } else {
        main_menu += ["MULTI"];
    }
    if (Enabled) {
        main_menu += ["CLEAR", "RESET"];
    } else {
        main_menu += ["RESET"];
    }
    main_menu += ["SLIDE", "DIRECTION", "DISTANCE", "SPEED"];
    if (Enabled) {
        main_menu += ["DISABLE"];
    } else {
        main_menu += ["ENABLE", "CLEAR"];
    }
    if (Debug) {
        main_menu += ["DEBUG OFF", "EXIT"];
    } else {
        main_menu += ["DEBUG ON", "EXIT"];
    }
    ShowMenu(menuMessage, main_menu);
}

// Show the specific menu page
// Pass in the full menu list
ShowMenu(string msg, list fm) {
    integer list_length = llGetListLength(fm);
    llSetTimerEvent(2.0 * LISTEN_TTL);   // If no response in time, return to previous state
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
    linksetValue = llLinksetDataRead(X_DIST_LSD_KEY);
    if (linksetValue != "") {
        Distance.x = (float)linksetValue;
    }
    linksetValue = llLinksetDataRead(Y_DIST_LSD_KEY);
    if (linksetValue != "") {
        Distance.y = (float)linksetValue;
    }
    linksetValue = llLinksetDataRead(Z_DIST_LSD_KEY);
    if (linksetValue != "") {
        Distance.z = (float)linksetValue;
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
    linksetValue = llLinksetDataRead(X_REVERSE_LSD_KEY);
    if (linksetValue != "") {
        xReverse = (integer)linksetValue;
    }
    linksetValue = llLinksetDataRead(Y_REVERSE_LSD_KEY);
    if (linksetValue != "") {
        yReverse = (integer)linksetValue;
    }
    linksetValue = llLinksetDataRead(Z_REVERSE_LSD_KEY);
    if (linksetValue != "") {
        zReverse = (integer)linksetValue;
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
    linksetDataWrite(id, X_DIST_LSD_KEY, (string)Distance.x, "X Distance to slide");
    linksetDataWrite(id, Y_DIST_LSD_KEY, (string)Distance.y, "Y Distance to slide");
    linksetDataWrite(id, Z_DIST_LSD_KEY, (string)Distance.z, "Z Distance to slide");
    // Duration of the slide
    linksetDataWrite(id, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
    // Speed of the slide
    linksetDataWrite(id, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
    // Slide axis
    linksetDataWrite(id, AXIS_LSD_KEY, Axis, "Slide axis");
    // Slide orientation
    linksetDataWrite(id, X_REVERSE_LSD_KEY, (string)xReverse, "Slide X direction");
    linksetDataWrite(id, Y_REVERSE_LSD_KEY, (string)yReverse, "Slide Y direction");
    linksetDataWrite(id, Z_REVERSE_LSD_KEY, (string)zReverse, "Slide Z direction");
}

// Writes the provided key/value pair to the prim's linkset datastore
integer linksetDataWrite(key id, string lsdKey, string value, string cfg) {
    string val = llStringTrim(value, STRING_TRIM);
    integer returnCode = llLinksetDataWrite(lsdKey, val);
    if (returnCode == LINKSETDATA_OK) {
        if (id) {
            llRegionSayTo(id, 0, "[Smooth Slider] " + cfg + " saved.");
        }
    } else if (returnCode != LINKSETDATA_NOUPDATE) {
        if (id) {
            llRegionSayTo(id, 0, "[Smooth Slider] " + cfg + " save failed (code " + (string)returnCode + ").");
        }
    }
    return returnCode;
}

setOpenPos(vector Dist) {
    if (xReverse) {
        Dist.x = -Dist.x;
    }
    if (yReverse) {
        Dist.y = -Dist.y;
    }
    if (zReverse) {
        Dist.z = -Dist.z;
    }
    Open = Home + Dist;
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
        Distance.x = Size.x;
        Distance.y = 0.0;
        Distance.z = 0.0;
        setSets("X");
    } else if (Axis == "Y") {
        Distance.x = 0.0;
        Distance.y = Size.y;
        Distance.z = 0.0;
        setSets("Y");
    } else if (Axis == "Z") {
        Distance.x = 0.0;
        Distance.y = 0.0;
        Distance.z = Size.z;
        setSets("Z");
    } else if (Axis == "XY") {
        Distance.x = Size.x;
        Distance.y = Size.y;
        Distance.z = 0.0;
    } else if (Axis == "XZ") {
        Distance.x = Size.x;
        Distance.y = 0.0;
        Distance.z = Size.z;
    } else if (Axis == "YZ") {
        Distance.x = 0.0;
        Distance.y = Size.y;
        Distance.z = Size.z;
    } else if (Axis == "XYZ") {
        Distance.x = Size.x;
        Distance.y = Size.y;
        Distance.z = Size.z;
    } else {
        Distance.x = Size.x;
        Distance.y = 0.0;
        Distance.z = 0.0;
        setAxis();
    }
    // Default duration is equal to the distance between the two positions
    Duration = llVecDist(Home, Home + Distance);
    // Default Speed is 1 mps
    Speed    = 1.0;
    Access   = 2;
    Constant = TRUE;
    xReverse = FALSE;
    yReverse = FALSE;
    zReverse = FALSE;
    setDatastoreValues(Owner);
}

setAxis() {
    Axis = "";
    if (Distance.x != 0.0) {
        Axis = "X";
    }
    if (Distance.y != 0.0) {
        Axis += "Y";
    }
    if (Distance.z != 0.0) {
        Axis += "Z";
    }
}

default {
    state_entry() {
        Owner = llGetOwner();
        Tcher = NULL_KEY;
        Rot   = llGetRot();
        Home  = llGetPos();
        State = "default";

        Distance.x = -9999.9;

        // Get the stored variable values
        getDatastoreValues();

        // Set the slide Axes and Single or Multi
        setAxis();

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
        // setDefaults() performs a Datastore update
        if (Distance.x == -9999.9) {
            setDefaults();
        } else {
            setDatastoreValues(Owner);
        }

        // Nothing after here in state_entry() should set any properties stored in the datastore
        setOpenPos(Distance);
        // Set open position
        if (Debug) {
            llOwnerSay("Distance = " + (string)Distance);
            llOwnerSay("Home     = " + (string)Home);
            llOwnerSay("Open     = " + (string)Open);
        }

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
                    if (Enabled) {
                        state opening;
                    } else {
                        state menu;
                    }
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
                    if (Enabled) {
                        state opening;
                    } else {
                        state menu;
                    }
                }
            }
        } else if (Access == 0) {
            if (Tcher == Owner) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    if (Enabled) {
                        state opening;
                    } else {
                        state menu;
                    }
                }
            }
        }
    }

    on_rez(integer num) {
        Owner = llGetOwner();
        string rezname = "Truth & Beauty Smooth Slider (example, rez me)";
        string newname = "Smooth Slider Example";
        if (llGetObjectName() == rezname) {
            llSetObjectName(newname);
        }
        getInfo(TRUE);
        string info = "\nTouch to slide open and close. Long touch to open the menu.";
        info += "\nSmooth Slider updates are free for life and will be available at:";
        info += "\n    https://github.com/missyrestless/Slider/releases";
        info += "\nThe latest Truth & Beauty Smooth Slider documentation can be found at:";
        info += "\n    https://github.com/missyrestless/Slider#readme";
        llOwnerSay(info);
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
        }
        llSetTimerEvent(Duration);
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
                    if (Enabled) {
                        state closing;
                    } else {
                        state menu;
                    }
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
                    if (Enabled) {
                        state closing;
                    } else {
                        state menu;
                    }
                }
            }
        } else if (Access == 0) {
            if (Tcher == Owner) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    if (Enabled) {
                        state closing;
                    } else {
                        state menu;
                    }
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
        }
        llSetTimerEvent(Duration);
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
                    if (Enabled) {
                        state opening;
                    } else {
                        state menu;
                    }
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
                    if (Enabled) {
                        state opening;
                    } else {
                        state menu;
                    }
                }
            }
        } else if (Access == 0) {
            if (Tcher == Owner) {
                if (holdTime >= 1.0) {
                    // Long press for dialog menu
                    // Handle dialog menu in its own state
                    state menu;
                } else {
                    if (Enabled) {
                        state opening;
                    } else {
                        state menu;
                    }
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
        pageNumber = 1;
        displayMainMenu();
    }

    listen(integer channel, string name, key id, string message) {
        string DIST_LSD_KEY;
        string LSD_KEY_DESC;
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
                setSets("X");
            } else if (message == "Y-AXIS") {
                setSets("Y");
            } else if (message == "Z-AXIS") {
                setSets("Z");
            } else if (message == "X") {
                Axis = "X";
                if (Distance.x == 0.0) {
                    setDefaults();
                }
                setSets("X");
                Multi = FALSE;
                setOpenPos(Distance);
                linksetDataWrite(id, AXIS_LSD_KEY, Axis, "Slide axis");
            } else if (message == "Y") {
                Axis = "Y";
                if (Distance.y == 0.0) {
                    setDefaults();
                }
                setSets("Y");
                Multi = FALSE;
                setOpenPos(Distance);
                linksetDataWrite(id, AXIS_LSD_KEY, Axis, "Slide axis");
            } else if (message == "Z") {
                Axis = "Z";
                if (Distance.z == 0.0) {
                    setDefaults();
                }
                setSets("Z");
                Multi = FALSE;
                setOpenPos(Distance);
                linksetDataWrite(id, AXIS_LSD_KEY, Axis, "Slide axis");
            } else if (message == "MULTI") {
                setAxis();
                Multi = TRUE;
            } else if (message == "SINGLE") {
                if (Distance == ZERO_VECTOR) {
                    Axis = "X";
                    setDefaults();
                    setSets("X");
                } else if (Distance.x != 0.0) {
                    Axis = "X";
                    Distance.y = 0.0;
                    Distance.z = 0.0;
                    setSets("X");
                } else if (Distance.y != 0.0) {
                    Axis = "Y";
                    Distance.x = 0.0;
                    Distance.z = 0.0;
                    setSets("Y");
                } else if (Distance.z != 0.0) {
                    Axis = "Z";
                    Distance.x = 0.0;
                    Distance.y = 0.0;
                    setSets("Z");
                }
                setAxis();
                Multi = FALSE;
                linksetDataWrite(id, X_DIST_LSD_KEY, (string)Distance.x, "X Distance to slide");
                linksetDataWrite(id, Y_DIST_LSD_KEY, (string)Distance.y, "Y Distance to slide");
                linksetDataWrite(id, Z_DIST_LSD_KEY, (string)Distance.z, "Z Distance to slide");
            } else if (message == "CLEAR") {
                state confirm;
            } else if (message == "RESET") {
                    llResetScript();
            } else if (message == "CONSTANT") {
                Constant = TRUE;
                linksetDataWrite(id, CONSTANT_LSD_KEY, (string)Constant, "Slide speed rate");
            } else if (message == "VARIABLE") {
                Constant = FALSE;
                linksetDataWrite(id, CONSTANT_LSD_KEY, (string)Constant, "Slide speed rate");
            } else if (message == "DIRECTION") {
                displayDirectionMenu();
                return;
            } else if (message == "DISTANCE") {
                displayDistanceMenu();
                return;
            } else if (message == "DEBUG OFF") {
                Debug = FALSE;
            } else if (message == "DEBUG ON") {
                Debug = TRUE;
            } else if (message == "FORWARD") {
                xReverse = FALSE;
                yReverse = FALSE;
                zReverse = FALSE;
                setOpenPos(Distance);
                linksetDataWrite(id, X_REVERSE_LSD_KEY, (string)xReverse, "Slide X direction");
                linksetDataWrite(id, Y_REVERSE_LSD_KEY, (string)yReverse, "Slide Y direction");
                linksetDataWrite(id, Z_REVERSE_LSD_KEY, (string)zReverse, "Slide Z direction");
            } else if (message == "REVERSE") {
                xReverse = TRUE;
                yReverse = TRUE;
                zReverse = TRUE;
                setOpenPos(Distance);
                linksetDataWrite(id, X_REVERSE_LSD_KEY, (string)xReverse, "Slide X direction");
                linksetDataWrite(id, Y_REVERSE_LSD_KEY, (string)yReverse, "Slide Y direction");
                linksetDataWrite(id, Z_REVERSE_LSD_KEY, (string)zReverse, "Slide Z direction");
            } else if (message == "X FORWARD") {
                xReverse = FALSE;
                setOpenPos(Distance);
                linksetDataWrite(id, X_REVERSE_LSD_KEY, (string)xReverse, "Slide X direction");
            } else if (message == "Y FORWARD") {
                yReverse = FALSE;
                setOpenPos(Distance);
                linksetDataWrite(id, Y_REVERSE_LSD_KEY, (string)yReverse, "Slide Y direction");
            } else if (message == "Z FORWARD") {
                zReverse = FALSE;
                setOpenPos(Distance);
                linksetDataWrite(id, Z_REVERSE_LSD_KEY, (string)zReverse, "Slide Z direction");
            } else if (message == "X REVERSE") {
                xReverse = TRUE;
                setOpenPos(Distance);
                linksetDataWrite(id, X_REVERSE_LSD_KEY, (string)xReverse, "Slide X direction");
            } else if (message == "Y REVERSE") {
                yReverse = TRUE;
                setOpenPos(Distance);
                linksetDataWrite(id, Y_REVERSE_LSD_KEY, (string)yReverse, "Slide Y direction");
            } else if (message == "Z REVERSE") {
                zReverse = TRUE;
                setOpenPos(Distance);
                linksetDataWrite(id, Z_REVERSE_LSD_KEY, (string)zReverse, "Slide Z direction");
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
                pageNumber = 1;
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
                pageNumber = 1;
                displayMainMenu();
            } else if (message == "EXIT") {
                pageNumber = 1;
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
                if (SetX) {
                    Distance.x = (float)dst;
                    DIST_LSD_KEY = X_DIST_LSD_KEY;
                    LSD_KEY_DESC = "X Distance to slide";
                    SetX = FALSE;
                } else if (SetY) {
                    Distance.y = (float)dst;
                    DIST_LSD_KEY = Y_DIST_LSD_KEY;
                    LSD_KEY_DESC = "Y Distance to slide";
                    SetY = FALSE;
                } else if (SetZ) {
                    Distance.z = (float)dst;
                    DIST_LSD_KEY = Z_DIST_LSD_KEY;
                    LSD_KEY_DESC = "Z Distance to slide";
                    SetZ = FALSE;
                }
                if (Constant) {
                    Duration = llVecDist(Home, Home + Distance);
                    linksetDataWrite(Owner, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
                } else {
                    Speed = llVecDist(Home, Home + Distance) / Duration;
                    linksetDataWrite(Owner, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
                }
                linksetDataWrite(id, DIST_LSD_KEY, dst, LSD_KEY_DESC);
                setOpenPos(Distance);
            } else if (llGetSubString(message, -4, -1) == " MPS") {
                string vel = llDeleteSubString(message, -4, -1);
                Speed = (float)vel;
                linksetDataWrite(Owner, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
                if (Constant) {
                    Duration = llVecDist(Home, Home + Distance);
                    linksetDataWrite(Owner, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
                }
            }
            // Re-send the dialog to keep the menu open
            if (inDistanceMenu) {
                displayDistanceMenu();
            } else if (inSpeedMenu) {
                displaySpeedMenu();
            } else if (inDirectMenu) {
                displayDirectionMenu();
            } else {
                displayMainMenu();
            }
        } else if (channel == inputChannel) {
            string valu = llStringTrim(message, STRING_TRIM);
            if (isFloat(valu)) {
                if (inDistanceMenu) {
                    if (SetX) {
                        Distance.x = (float)valu;
                        DIST_LSD_KEY = X_DIST_LSD_KEY;
                        LSD_KEY_DESC = "X Distance to slide";
                        SetX = FALSE;
                    } else if (SetY) {
                        Distance.y = (float)valu;
                        DIST_LSD_KEY = Y_DIST_LSD_KEY;
                        LSD_KEY_DESC = "Y Distance to slide";
                        SetY = FALSE;
                    } else if (SetZ) {
                        Distance.z = (float)valu;
                        DIST_LSD_KEY = Z_DIST_LSD_KEY;
                        LSD_KEY_DESC = "Z Distance to slide";
                        SetZ = FALSE;
                    }
                    if (Constant) {
                        Duration = llVecDist(Home, Home + Distance);
                        linksetDataWrite(Owner, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
                    } else {
                        Speed = llVecDist(Home, Home + Distance) / Duration;
                        linksetDataWrite(Owner, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
                    }
                    linksetDataWrite(id, DIST_LSD_KEY, valu, LSD_KEY_DESC);
                    setOpenPos(Distance);
                } else if (inSpeedMenu) {
                    Speed = (float)valu;
                    linksetDataWrite(Owner, SPEED_LSD_KEY, (string)Speed, "Speed of the slide");
                    if (Constant) {
                        Duration = llVecDist(Home, Home + Distance);
                        linksetDataWrite(Owner, DURATION_LSD_KEY, (string)Duration, "Duration of the slide");
                    }
                }
            } else {
                llRegionSayTo(id, 0, "[Smooth Slider] " + valu + " is not a valid number.");
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
