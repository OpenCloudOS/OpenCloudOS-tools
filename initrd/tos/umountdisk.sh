#!/bin/bash

mount | grep mnt | awk '{print $3}' | sort -r | xargs umount
