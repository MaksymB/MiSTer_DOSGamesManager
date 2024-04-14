#!/usr/bin/env bash

# Exit immediately if any command fails
set -e

app_name="0MHz DOS Collection"

escape_string() {
    echo "$1" | sed 's/ /\\ /g' | sed 's/&/\\&/g'
}

file_size() {
    local file_size=$(stat -c %s "$1")

    if (( file_size >= 1024 )); then
        local file_size_mb=$(echo "scale=1; $file_size / 1024 / 1024" | bc)
        printf "%6.1f MB\n" "$file_size_mb"
    else
        printf "%6d Bytes\n" "$file_size"
    fi
}

interactive_install() {
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

    # Find 0Mhz DOS Collection location by checking all USB drives one by one
    # and the SD card.
    games_collection_root=""
    subd_0mhz="0mhz-dos"
    for p in ${all_paths[@]}; do
        gcr="$p/$subd_0mhz"
        if [ -d "$gcr" ]; then
            games_collection_root="$gcr"
            break
        fi
    done

    if [ ! -d "$games_collection_root" ]; then
        echo "No '$subd_0mhz' dir found neither on USB drives nor on SD card."
        exit 1
    fi

    # Find ao486 games dir by checking all USB drives one by one and the SD
    # card.
    ao486_games_dir=""
    subd_ao486="games/ao486"
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

    local scripts_dir=$(dirname "$(readlink -f "$0")")

    # Find all game archives available for installation
    game_archives=()

    cd "$games_collection_root"
    for file in *.zip; do
        game_archives+=("${file%.*}")
        s="$(file_size "$file")"

        game_archives+=("$s")
    done

    cd "$scripts_dir"

    local selected_game=$(dialog --backtitle "$app_name" --menu "Choose a game to install:" 15 70 10 "${game_archives[@]}" --stdout)

    if [ -n "$selected_game" ]; then
        local ga="$(escape_string "$selected_game")"
        local gc="$(escape_string "$games_collection_root")"
        local td="$(escape_string "$ao486_games_dir")"
        local install_command="$0 $ga $gc $td"

        dialog --backtitle "$app_name" --prgbox "${selected_game} installation" "$install_command" 20 80
    fi

    clear
}

install_game() {
    local selected_game="$1"
    local games_collection_root="$2"
    local ao486_games_dir="$3"
    local temp_dir="$games_collection_root/.tmp/"

    echo "Installing ${selected_game}..."
    echo

    if [ -d "$temp_dir" ]; then
        echo "Temporary directory from previous run found. Removing..."
        rm -rf "$temp_dir"

        if [ -d "$temp_dir" ]; then
        echo "ERROR: failed to remove temporary directory."
        exit 1
        fi

        echo
    fi

    archive_file_path="$games_collection_root/$selected_game.zip"

    mkdir "$temp_dir"

    echo "Extracting $selected_game..."
    echo "  from: $archive_file_path"
    echo "  to:   $temp_dir"
    unzip -q "$archive_file_path" -d "$temp_dir"
    echo

    local target_media_dir="$ao486_games_dir/media"
    echo "Installing game files..."
    rsync -avP "$temp_dir/games/ao486/media/" "$target_media_dir"
    echo

    echo "This directory contains games from 0MHz DOS Collection." > "$target_media_dir/README.md"

    echo "Adding the game to 'DOS Games' group..."
    cp -ru "$temp_dir/_DOS Games" "/media/fat"
    echo

    rm -rf "$temp_dir"

    echo "Done!"
}

if [ $# -eq 0 ]; then
    interactive_install
else
    install_game "$1" "$2" "$3"
fi

