usage () {
    echo "Usage: sysload [-c port] [-g port]"
    echo "  -c port     Set COM port connected to CPU"
    echo "  -g port     Set COM port connected to GPU"
    exit 1
}

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

python makedat.py --tile_palette ../Resources/sprites.txt ../Software/sprites.dat
python makedat.py --tile_palette ../Resources/tiles.txt ../Software/tiles.dat
python makedat.py --color_palette ../Resources/sprite_color_palettes.txt ../Software/sprite_color_palettes.dat
python makedat.py --color_palette ../Resources/tile_color_palettes.txt ../Software/tile_color_palettes.dat
python makedat.py --tile_map ../Resources/tile_maps.txt ../Software/tile_maps.dat

bstc ../Software/cpu.spin -f -d$cpu_port -p2 &
bstc ../Software/gpu.spin -f -d$gpu_port -p2 &
wait