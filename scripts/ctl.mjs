#!/usr/bin/env zx

// Usage:
// ctl.mjs snapshot list --app whisparr --namespace default

import { Snapshot } from './lib/Snapshot.class.mjs';

$.verbose = false

const COMMAND = argv["_"][0]
const ARG     = argv["_"][1]
const DEBUG   = argv["debug"] || false
const HELP    = argv["help"]  || false

if (DEBUG) { $.verbose = true }
switch(COMMAND) {
    case "snapshot":
        const snapshot = new Snapshot(DEBUG, HELP)
        switch(ARG) {
            case "list":
                await snapshot.List()
                break;
            case "create":
                await snapshot.Create()
                break;
            default:
                console.log(`404: ${ARG} arg not found`)
            }
        break;
    default:
        console.log(`404: ${COMMAND} command not found`)
}
