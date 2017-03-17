#!/bin/sh

pistachio_board_detect() {
        board_name=`grep "^machine" /proc/cpuinfo | sed "s/machine.*: IMG \(.*\)/\1/g" | awk '{print tolower($1)"_"$NF}'`
        model=`grep "^machine" /proc/cpuinfo | sed "s/machine.*: \(.*\)/\1/g" | sed "s/.* - \(.*\)/\1/g"`
        [ -z "$board_name" ] && board_name="unknown"
        [ -z "$model" ] && model="unknown"
        [ -e "/tmp/sysinfo/" ] || mkdir -p "/tmp/sysinfo/"
        echo $board_name > /tmp/sysinfo/board_name
        echo $model > /tmp/sysinfo/model
}

pistachio_board_model() {
        local model

        [ -f /tmp/sysinfo/model ] && model=$(cat /tmp/sysinfo/model)
        [ -z "$model" ] && model="unknown"

        echo "$model"
}

pistachio_board_name() {
        local name

        [ -f /tmp/sysinfo/board_name ] && name=$(cat /tmp/sysinfo/board_name)
        [ -z "$name" ] && name="unknown"

        echo "$name"
}
