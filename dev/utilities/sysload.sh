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

echo Converting resources...

python makedat.py --tile_palette ../resources/sprites.txt ../software/sprites.dat
python makedat.py --tile_palette ../resources/tiles.txt ../software/tiles.dat
python makedat.py --color_palette ../resources/sprite_color_palettes.txt ../software/sprite_color_palettes.dat
python makedat.py --color_palette ../resources/tile_color_palettes.txt ../software/tile_color_palettes.dat
python makedat.py --tile_map ../resources/tile_maps.txt ../software/tile_maps.dat

echo Compiling...

bstc ../Software/cpu.spin -q
bstc ../Software/gpu.spin -q

echo Programming...

bstc -p2 ../Software/cpu.spin -f -d$cpu_port -q &
bstc -p2 ../Software/gpu.spin -f -d$gpu_port -q &
wait

echo Done!