#!/bin/sh

CONFIG_PATH="/configs"
RAW_CONFIG_PATH="/raw_configs"
CONFIGED_FLAG="/configs/.configed"

if [ ! -f $CONFIGED_FLAG ]; then
    if [ ! -d $CONFIG_PATH ]; then
        echo "Creating config directory"
        mkdir -p $CONFIG_PATH
    fi

    # Copy the raw config files to the config path
    echo "Copying $RAW_CONFIG_PATH to $CONFIG_PATH"
    cp -r $RAW_CONFIG_PATH/* $CONFIG_PATH

    # Create the flag file
    echo "Creating configed flag"
    touch $CONFIGED_FLAG
else
    echo "Config directory already exists"
fi;

tail -f /dev/null