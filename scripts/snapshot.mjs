#!/usr/bin/env zx

// Usage:
// snapshot.mjs list --app whisparr --namespace default

import { create, list } from './lib/snapshot.mjs';

$.verbose = false

const action = argv["_"][0]
const app = argv["app"] || process.env.APP
const namespace = argv["namespace"] || process.env.NAMESPACE

if (!app)       { throw new Error("Argument --app or envirornment variable APP not set") }
if (!namespace) { throw new Error("Argument --namespace or envirornment variable NAMESPACE not set") }

switch(action) {
    case "create":
        await create(app, namespace)
        break;
    case "list":
        await list(app, namespace)
        break;
    default:
        console.log(`404: ${action} not found`)
}
