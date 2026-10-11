////////////// Smooth Slider Follower \\\\\\\\\\\\\\
//                                                //
//        Follow or Mirror a Smooth Slider        //
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
// 11-Oct-2026 Created by Missy Restless <missyrestless@gmail.com>

string    VERSION  = "1.1.1";

integer   Access   = 1;        // 0 = Owner, 1 = Group, 2 = Public
integer   Debug    = FALSE;    // Set to TRUE for verbose debug output
integer   Enabled  = TRUE;     // Whether touch to slide is enabled
integer   Mirror   = FALSE;    // Whether to mirror a Slider's movements when following
float     Duration = 4.0;      // How long to slide in seconds

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
integer objListenID;         // Follower channel ID
integer objChannel;          // Channel for communication between followers, based on owner
integer pageNumber     = 1;  // Dialog Menu page number
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

moveToTarget(vector dst) {
    if (Debug) {
        llOwnerSay("In Follower moveToTarget(dst) with vector = " + (string)dst);
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

followSlider(string msg) {
    if (llJsonValueType(msg, []) != JSON_INVALID) {
        string dst = llJsonGetValue(msg, ["dest"]);
        string dur = llJsonGetValue(msg, ["time"]);
        vector dest = (vector)dst;
        Duration = (float)dur;
        if (Mirror) {
            moveToTarget(-dest);
        } else {
            moveToTarget(dest);
        }
    }
}

string getInfo(integer show) {
    // Retrieve current datastore values
    getDatastoreValues();

    string info  = "Truth & Beauty Smooth Slider Follower " + VERSION + "\n";
    string slurl = getSlurl();
    info += "\nLocation:\t" + slurl;
    info += "\nState:     \t";
    if (Enabled) {
        info += "ENABLED";
    } else {
        info += "DISABLED";
    }
    if (Mirror) {
        info += " and MIRROR";
    } else {
        info += " and FOLLOW";
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

displayMainMenu() {
    llListenRemove(dialogHandle);
    dialogHandle = llListen(dialogChannel, "", Tcher, "");
    list main_menu = [];

    menuMessage = getInfo(FALSE);
    menuMessage += "\n\nCLEAR = Clear storage, reset to default values";
    menuMessage += "\nRESET = Reset scripts, storage persists";
    if (Mirror) {
        menuMessage += "\nFOLLOW = Stop mirroring, follow directly";
        main_menu += ["FOLLOW"];
    } else {
        menuMessage += "\nMIRROR = Mirror the Smooth Slider movement";
        main_menu += ["MIRROR"];
    }
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
    if (Enabled) {
        main_menu += ["CLEAR", "RESET"];
    } else {
        main_menu += ["RESET"];
    }
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
}

setDatastoreValues(key id) {
    //
    // Set all configuration values stored in the linkset datastore
    //
    // Access restrictions
    linksetDataWrite(id, ACCESS_LSD_KEY, (string)Access, "Access restrictions");
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

default {
    state_entry() {
        Owner = llGetOwner();
        Tcher = NULL_KEY;

        // Get the stored variable values
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

        setDatastoreValues(Owner);

        // Compute a negative communications channel based on prim UUID
        dialogChannel   = 0x80000000 | (integer) ( "0x" + (string) llGetKey() );
        // Compute a large negative channel number based on the object owner
        // All followers owned by the same owner will use the same channel
        objChannel = 0x80000000 | (integer) ( "0x" + (string) Owner );
        llListenRemove(objListenID);
        objListenID = llListen(objChannel, "", NULL_KEY, "");
        state follow;
    }

    touch_start(integer num_detected) {
        Tcher = llDetectedKey(0);
        // Ensure only the owner or group members triggers the timer start check
        if (Access == 2) {
            // In Public mode only the owner and group members have access to the menu
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                state menu;
            } else {
                Tcher = NULL_KEY;
            }
        } else if (Access == 1) {
            // In Group mode only the owner and group members have access
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                state menu;
            } else {
                Tcher = NULL_KEY;
            }
        } else if (Access == 0) {
            // In Owner mode only the owner has access
            if (Tcher == Owner) {
                state menu;
            } else {
                Tcher = NULL_KEY;
            }
        }
    }

    on_rez(integer num) {
        Owner = llGetOwner();
        string rezname = "Truth & Beauty Smooth Slider Follower (example, rez me)";
        string newname = "Smooth Slider Follower Example";
        if (llGetObjectName() == rezname) {
            llSetObjectName(newname);
        }
        getInfo(TRUE);
        string info = "\nTouch to open the Follower menu.";
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

state menu {
    state_entry() {
        pageNumber = 1;
        displayMainMenu();
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == dialogChannel) {
            if (message == "DISABLE") {
                Enabled = FALSE;
            } else if (message == "ENABLE") {
                Enabled = TRUE;
            } else if (message == "CLEAR") {
                state confirm;
            } else if (message == "RESET") {
                    llResetScript();
            } else if (message == "DEBUG OFF") {
                Debug = FALSE;
            } else if (message == "DEBUG ON") {
                Debug = TRUE;
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
            } else if (message == "EXIT") {
                pageNumber = 1;
                state follow;
            } else if (message == "<<< Prev") {
                pageNumber--;
            } else if (message == "Next >>>") {
                pageNumber++;
            }
            // Re-send the dialog to keep the menu open
            displayMainMenu();
        } else if (channel == objChannel) {
            followSlider(message);
        }
    }

    timer() {
        state follow;
    }

    state_exit() {
        setDatastoreValues(Tcher);
        llSetTimerEvent(0);
    }
}

state confirm {
    state_entry() {
        llListenRemove(dialogHandle);
        dialogHandle = llListen(dialogChannel, "", Tcher, "");
        llSetTimerEvent(LISTEN_TTL);

        string msg = "This will clear all customized settings from storage, reset to default values, and restore to original position";
        msg += "\nAre you sure you want to proceed?";
        llDialog(Owner, msg, ["YES", "NO"], dialogChannel);
    }

    listen(integer channel, string name, key id, string message) {
        llListenRemove(dialogHandle);
        if (message == "YES") {
            llLinksetDataReset();
            state default;
        } else if (message == "NO") {
            if (Debug) llOwnerSay("Clear linkset storage action cancelled.");
        }
        state menu;
    }

    timer() {
        llListenRemove(dialogHandle);
        llSetTimerEvent(0.0);
        state menu;
    }
}

// State for following another Slider's movements
state follow {
    state_entry() {
        Tcher = NULL_KEY;
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == objChannel) {
            followSlider(message);
        }
    }

    touch_start(integer num_detected) {
        Tcher = llDetectedKey(0);
        // Ensure only the owner or group members triggers the timer start check
        if (Access == 2) {
            // In Public mode only the owner and group members have access to the menu
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                state menu;
            } else {
                Tcher = NULL_KEY;
            }
        } else if (Access == 1) {
            // In Group mode only the owner and group members have access
            if ((llDetectedGroup(0)) || (Tcher == Owner)) {
                state menu;
            } else {
                Tcher = NULL_KEY;
            }
        } else if (Access == 0) {
            // In Owner mode only the owner has access
            if (Tcher == Owner) {
                state menu;
            } else {
                Tcher = NULL_KEY;
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
