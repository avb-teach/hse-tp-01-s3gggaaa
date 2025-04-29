#!/bin/bash

# Парсинг аргументов
max_depth=""
input_dir=""
output_dir=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            max_depth="$2"
            shift 2
            ;;
        *)
            if [[ -z "$input_dir" ]]; then
                input_dir="$1"
            else
                output_dir="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$input_dir" || -z "$output_dir" ]]; then
    echo "Usage: $0 [--max_depth N] input_dir output_dir"
    exit 1
fi

if [[ ! -d "$input_dir" ]]; then
    echo "Input directory does not exist: $input_dir"
    exit 1
fi

mkdir -p "$output_dir"

process_file() {
    local file="$1"
    local output_dir="$2"
    local max_depth="$3"

    local relative_path
    relative_path=$(realpath --relative-to="$input_dir" "$file")

    if [[ -n "$max_depth" ]]; then
        IFS='/' read -ra parts <<< "$relative_path"
        local num_parts=${#parts[@]}
        local depth=$((num_parts - 1))

        if [[ $depth -le $max_depth ]]; then
            dest="$output_dir/$relative_path"
        else
            trimmed_parts=("${parts[@]:$max_depth}")
            trimmed_path=$(IFS='/' ; echo "${trimmed_parts[*]}")
            dest="$output_dir/$trimmed_path"
        fi

        dest_dir=$(dirname "$dest")
        mkdir -p "$dest_dir"
        cp -- "$file" "$dest"
    else
        filename=$(basename "$file")
        base="${filename%.*}"
        ext="${filename##*.}"

        if [[ "$base" == "$ext" ]]; then
            ext=""
        else
            ext=".$ext"
        fi

        counter=1
        new_name="$base$ext"

        while [[ -e "$output_dir/$new_name" ]]; do
            new_name="${base}_$counter$ext"
            ((counter++))
        done

        cp -- "$file" "$output_dir/$new_name"
    fi
}

export -f process_file
export input_dir output_dir max_depth

find "$input_dir" -type f -print0 | xargs -0 -I {} bash -c 'process_file "{}" "$output_dir" "$max_depth"'