#!/usr/bin/env bash

# Exit immediately if any command fails
set -e

app_name="0MHz DOS Collection"
dos_games_dir="/media/fat/_DOS Games/"
scripts_dir="$(dirname "$(readlink -f "$0")")"


escape_string() {
    echo "$1" | sed 's/ /\\ /g' | sed 's/&/\\&/g'
}

interactive_uninstall() {
    local all_paths=(
        "/media/usb0"
        "/media/usb1"
        "/media/usb2"
        "/media/usb3"
        "/media/usb4"
        "/media/usb5"
        "/media/usb6"
        "/media/usb7"
        "/media/fat"
    )

    # Find AO486 games dir by checking all USB drives one by one and the SD
    # card.
    ao486_games_dir=""
    subd_ao486="games/AO486"

    for p in ${all_paths[@]}; do
        gs="$p/$subd_ao486"
        if [ -d "$gs" ]; then
            ao486_games_dir="$gs"
        break
        fi
    done

    if [ ! -d "$ao486_games_dir" ]; then
        echo "No '$subd_ao486' dir found neither on USB drives nor on SD card."
        exit 1
    fi

    # Find all installed games
    installed_games=()

    cd "$dos_games_dir"
    for file in *.mgl; do
        installed_games+=("${file%.*}")
        installed_games+=("")
    done
    cd "$scripts_dir"

    local selected_game=$(dialog --backtitle "$app_name" --menu "Choose a game to uninstall:" 15 70 10 "${installed_games[@]}" --stdout)

    if [ -n "$selected_game" ]; then
        local ga="$(escape_string "$selected_game")"
        local td="$(escape_string "$ao486_games_dir")"
        local install_command="$0 $ga $td"

        dialog --backtitle "$app_name" --prgbox "${selected_game} removing" "$install_command" 20 80
    fi

    clear
}

game_subdir() {
    echo $(grep -m 1 -o 'path="media/[^/]*' "$1" | sed 's/path="media\///')
}

uninstall_game() {
    local selected_game="$1"
    local ao486_games_dir="$2"

    local mgl_file_name="$selected_game.mgl"
    local mgl_path="$dos_games_dir/$mgl_file_name"

    subdir_name="$(game_subdir "$mgl_path")"

    local dir_to_remove="$ao486_games_dir/media/$subdir_name/"
    if [ -n "$subdir_name" ] && [ -d "$dir_to_remove" ]; then
        echo "Removing game files in $dir_to_remove..."
        rm -r "$dir_to_remove"
        echo

        cd "$dos_games_dir"
        for file in *.mgl; do
            sbd="$(game_subdir "$file")"
	    if [ "$sbd" == "$subdir_name" ] && [ "$file" != "$mgl_file_name" ] ; then
	        echo "Warning! ${file%.*} is using the same game files."
                echo "Removing ${file%.*} from 'DOS Games' group..."
                rm "$file"
                echo
	    fi
        done
        cd "$scripts_dir"
    else
        echo "Warning! Game directory not found."
    fi

    echo "Removing $selected_game from 'DOS Games' group..."
    rm "$mgl_path"
    echo

    echo "Done!"
}

if [ $# -eq 0 ]; then
    interactive_uninstall
else
    uninstall_game "$1" "$2"
fi

