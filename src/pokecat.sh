script_path="$(readlink -f "${0}")"
src_path="$(dirname "${script_path}")"
root_path="$(dirname "${src_path}")"
. "${src_path}/utils.sh"
check_dependencies catimg

show_help() {
cat << EOF
Usage: ${0##*/} [-hv] [-s/--shiny]...
Print a Pokemon sprite from a res folder
    -h          display this help and exit
    -s/--shiny  set the Pokemon to be shiny
EOF
}

# One Pokemon of this {SHINY_CHANCE_DENOMINATOR} will be shiny
SHINY_CHANCE_DENOMINATOR=512

is_shiny=0
# Loop to receive arguments
while :; do
    case $1 in
        -h|-\?|--help)
            show_help    # Display a usage synopsis.
            exit
            ;;
        -s|--shiny)
            is_shiny=1 # The Pokemon will be shiny
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)
            break
    esac
    shift
done

# Check that ./res is indeed a directory
if [ ! -d "${root_path}/res" ]; then
    printf "\e[31m${script_path}: ${root_path}/res is not a directory. Run ${src_path}/make_res.sh.\e[0m\n" >& 2
    exit 2
fi

# Get a random pokemon
# head -n 1 reads only the first line and then exits. When sort tries to write data to the closed pipe, the system raises a "Broken pipe" signal (SIGPIPE)
pokemon="$(ls "${root_path}/res/"*.png | sort -R | awk "NR==1" | xargs basename -s ".png")"

# Get a random number, and if it's 1, then choose a shiny
SHINY_NUMBER="$(shuf -i 1-${SHINY_CHANCE_DENOMINATOR} -n 1)"
if [[ "${SHINY_NUMBER}" -eq 1 ]]; then
	is_shiny=1
fi

# Show the pokemon. Replace catimg with the terminal image viewer of your choice
if [[ "${is_shiny}" -eq 1 ]]; then
	catimg "${root_path}/res/shiny/${pokemon}.png"
	printf "\e[1;33m${pokemon}\e[0m, and it's shiny!\n"
else
	catimg "${root_path}/res/${pokemon}.png"
	printf "\e[1m${pokemon}\e[0m\n"
fi


