#!/bin/bash -e

# efa needs ib_core and ib_uverbs to be loaded
# assume it is mounted at /lib/modules (defualt path for modprobe)

_unload_driver() {
    local efa_refs=0

    if [ -f /sys/module/efa/refcnt ]; then
        efa_refs=$(< /sys/module/efa/refcnt)
    fi

    if [ ${efa_refs} -gt 0 ]; then
        # run lsmod to debug module usage
        lsmod | grep efa
        echo "Could not unload efa kernel module, module is in use" >&2
        return 1
    fi

    rmmod efa
    return 0
}

install() {
    echo "Unloading efa kernel module"
    _unload_driver || exit 1

    echo "Loading efa kernel module"
    modprobe ib_core
    modprobe ib_uverbs
    modprobe -d /opt efa || exit 1

    echo "Done, now waiting for signal"
    sleep infinity &
    trap "echo 'Caught signal'; _unload_driver && { kill $!; exit 0; }" HUP INT QUIT PIPE TERM
    trap - EXIT
    while true; do wait $! || continue; done
    exit 0
}

install
