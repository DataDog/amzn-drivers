#!/bin/bash -e

# efa_nv_peermem needs nvidia to be loaded

_unload_driver() {
    local efa_nv_peermem_refs=0

    if [ -f /sys/module/efa_nv_peermem/refcnt ]; then
        efa_nv_peermem_refs=$(< /sys/module/efa_nv_peermem/refcnt)
    fi

    if [ ${efa_nv_peermem_refs} -gt 0 ]; then
        # run lsmod to debug module usage
        lsmod | grep efa_nv_peermem
        echo "Could not unload efa_nv_peermem kernel module, module is in use" >&2
        return 1
    fi

    rmmod efa_nv_peermem
    return 0
}

install() {
    echo "Unloading efa_nv_peermem kernel module"
    _unload_driver || exit 1

    until lsmod | grep -q nvidia; do
        echo "Waiting for nvidia-driver to be installed..."
        sleep 10
    done

    echo "Loading efa_nv_peermem kernel module"
    modprobe -d /opt efa_nv_peermem || exit 1

    echo "Done, now waiting for signal"
    sleep infinity &
    trap "echo 'Caught signal'; _unload_driver && { kill $!; exit 0; }" HUP INT QUIT PIPE TERM
    trap - EXIT
    while true; do wait $! || continue; done
    exit 0
}

install
