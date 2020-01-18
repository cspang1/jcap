usage () {
    echo "Usage: sysload [-c port] [-g port]"
    echo "  -c port     Set COM port connected to CPU"
    echo "  -g port     Set COM port connected to GPU"
    exit 1
}
set -e

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cpu_flag=0
gpu_flag=0

while getopts ":c:g:qh" opt; do
    case ${opt} in
        c )
            cpu_port=$OPTARG
            cpu_flag=1
            ;;
        g )
            gpu_port=$OPTARG
            gpu_flag=1
            ;;
        :  ) 
            echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        \? | h )
            usage
            ;;
    esac
done

if [[ "$cpu_flag" -eq 0 || "$gpu_flag" -eq 0 ]]; then usage; fi

cd $parent_path

echo Compiling...

bstc cpu.spin -q
bstc gpu.spin -q

echo Programming...

bstc -p2 cpu.spin -f -d$cpu_port -q &
bstc -p2 gpu.spin -f -d$gpu_port -q &
wait

echo Done!