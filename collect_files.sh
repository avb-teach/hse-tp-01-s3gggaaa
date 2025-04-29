#!/bin/bash

max_depth=-1
input_dir=""
output_dir=""

args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            max_depth="$2"
            shift 2
            ;;
        *)
            args+=("$1")
            shift
            ;;
    esac
done

if [[ ${#args[@]} -ne 2 ]]; then
    echo "Usage: $0 [--max_depth N] input_dir output_dir"
    exit 1
fi

input_dir="${args[0]}"
output_dir="${args[1]}"

if [[ ! -d "$input_dir" ]]; then
    echo "Input directory does not exist: $input_dir"
    exit 1
fi

mkdir -p "$output_dir"

if [[ $max_depth -ge 0 ]]; then
    find "$input_dir" -type f | while read -r file; do
        relative_path=$(realpath --relative-to="$input_dir" "$file")
        IFS='/' read -ra parts <<< "$relative_path"
        num_dirs=$((${#parts[@]} - 1)) 
        
        if [[ $num_dirs -gt $max_depth ]]; then
            start_index=$((num_dirs - max_depth))
            if [[ $start_index -lt 0 ]]; then
                start_index=0
            fi
            new_parts=("${parts[@]:$start_index}")
        else
            new_parts=("${parts[@]}")
        fi
        
        new_relative_path=$(IFS='/'; echo "${new_parts[*]}")
        dest="$output_dir/$new_relative_path"
        mkdir -p "$(dirname "$dest")"
        cp "$file" "$dest"
    done
else
    find "$input_dir" -type f | while read -r file; do
        filename=$(basename "$file")
        name="${filename%.*}"
        extension="${filename##*.}"
        
        if [[ "$name" == "$filename" ]]; then
            extension=""
        fi
        
        dest_name="$filename"
        counter=1
        
        while [[ -e "$output_dir/$dest_name" ]]; do
            if [[ -z "$extension" ]]; then
                dest_name="${name}_$counter"
            else
                dest_name="${name}_$counter.${extension}"
            fi
            ((counter++))
        done
        
        cp "$file" "$output_dir/$dest_name"
    done
fi