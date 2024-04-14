#!/bin/bash

input_file="dos_games_manager.sh"

hash=$(md5 "$input_file" | cut -d' ' -f4)
size=$(wc -c < "$input_file")
timestamp=$(stat -f %m "$input_file")

# Generate JSON
cat <<EOF > dos_games_manager.json
{
    "base_files_url": "",
    "db_files": [],
    "db_id": "dos_games_manager",
    "db_url": "https://raw.githubusercontent.com/MaksymB/MiSTer_DOSGamesManager/main/dos_games_manager.json",
    "default_options": {},
    "files": {
        "Scripts/$input_file": {
            "hash": "$hash",
            "size": $size,
            "url": "https://raw.githubusercontent.com/MaksymB/MiSTer_DOSGamesManager/main/dos_games_manager.sh"
        }
    },
    "folders": {
        "Scripts": {}
    },
    "timestamp": $timestamp,
    "zips": {}
}
EOF

