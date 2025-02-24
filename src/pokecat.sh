script_path="$(readlink -f "${0}")"
src_path="$(dirname "${script_path}")"
root_path="$(dirname "${src_path}")"
. "${src_path}/utils.sh"
check_dependencies catimg

show_help() {
cat << EOF
Usage: ${0##*/} [-hv] [-s/--shiny] [-g/--gen GEN] [-n/--num NUM]
Print a Pokemon sprite from a res folder
    -h              display this message and exit
    -s/--shiny      set the Pokemon to be shiny
    -g/--gen GEN    get a Pokemon from a specific gen
    -n/--num NUM    get a Pokenon with a specific number
EOF
}

exit_error() {
    printf '%s\n' "$1" >&2
    exit 1
}

# One Pokemon of this {SHINY_CHANCE_DENOMINATOR} will be shiny
SHINY_CHANCE_DENOMINATOR=256
# The total number of gens
NUM_GENS=4

LAST_POKEMON_GEN="151 251 386 493"
# Get the Pokedex number of the last Pokemon of a given gen
get_last_pokemon() {
    local gen=$1
    set -- $LAST_POKEMON_GEN  # Convert string to positional params
    eval echo \${$gen}
}

# Get the Pokedex number of the first Pokemon of a given gen
get_first_pokemon() {
	local gen=$1
	if [[ "${gen}" -eq 1 ]]; then
		echo 1
	else
		last_prev=$(get_last_pokemon $((gen - 1)))
		echo $((last_prev + 1))
	fi
}


is_shiny=0
gen=0
num=0
# Loop to receive arguments
while :; do
    case $1 in
        -h|-\?|--help)
            show_help # Display a usage synopsis.
            exit
            ;;
        -s|--shiny)
            is_shiny=1 # The Pokemon will be shiny
            ;;
		-g|--gen)
			if [[ "$2" ]]; then
                gen=$2
				# Validate the value of gen
				if ! [ "${gen}" -ge 0 ]; then
					exit_error "ERROR: --gen must receive a value between 1 and ${NUM_GENS}."
				elif [[ "${gen}" -gt "${NUM_GENS}" ]]; then
					exit_error "ERROR: --gen must receive a value between 1 and ${NUM_GENS}."
				fi
                shift
            else
                exit_error 'ERROR: "--gen" requires a non-empty option argument.'
            fi
			;;
		-n|--num)
			if [[ "$2" ]]; then
                num=$2
				# Get the last Pokedex entry we support
				last_pokemon=$(get_last_pokemon ${NUM_GENS})
				# Validate the value of num
				if ! [ "${gen}" -ge 0 ]; then
					exit_error "ERROR: --num must receive a value between 1 and ${last_pokemon}."
				elif [[ "${num}" -gt "${last_pokemon}" ]]; then
					exit_error "ERROR: --num must receive a value between 1 and ${last_pokemon}."
				fi
                shift
            else
                exit_error 'ERROR: "--num" requires a non-empty option argument.'
            fi
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


if [[ "${num}" -ge 1 ]]; then
	# If we have specified a number
	pokemon="$(ls "${root_path}/res/"*.png | grep "/${num}-" | sort -R | awk "NR==1" | xargs basename -s ".png")"
elif [[ "${gen}" -ge 1 ]]; then
	# If we have specified a gen
	first_pokemon=$(get_first_pokemon ${gen})
	last_pokemon=$(get_last_pokemon ${gen})
	pokemon="$(ls "${root_path}/res/"*.png | awk -v min="${first_pokemon}" -v max="${last_pokemon}" -F'/' '{file=$NF; sub(/\.png$/, "", file); split(file, a, "-"); if (a[1] >= min && a[1] <= max) print}' | sort -R | awk "NR==1" | xargs basename -s ".png")"
else
	# If we haven't specified a gen or a number
    pokemon="$(ls "${root_path}/res/"*.png | sort -R | awk "NR==1" | xargs basename -s ".png")"
fi

# Get a random number, and if it's 1, then choose a shiny
SHINY_NUMBER="$(shuf -i 1-${SHINY_CHANCE_DENOMINATOR} -n 1)"
if [[ "${SHINY_NUMBER}" -eq 1 ]]; then
	is_shiny=1
fi

# Show the Pokemon. Replace catimg with the terminal image viewer of your choice
if [[ "${is_shiny}" -eq 1 ]]; then
	catimg "${root_path}/res/shiny/${pokemon}.png"
	printf "\e[1;33m${pokemon}\e[0m, and it's shiny!\n"
else
	catimg "${root_path}/res/${pokemon}.png"
	printf "\e[1m${pokemon}\e[0m\n"
fi

