#!/usr/bin/env zx
import { $, argv } from 'zx'
import { commandRunner } from './lib/index.mjs'

argv.debug ? $.verbose = true : $.verbose = false

await commandRunner(argv._[1], argv._[2])
