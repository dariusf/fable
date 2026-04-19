#!/bin/bash

files=(../examples/*.md)

for file in "${files[@]}"; do
  contents="$(sed 's/"/\&quot;/g' < "$file")"
  name=$(python3 <<EOF
print('$file'.split('/')[-1].removesuffix('.md').replace('_', ' ').title())
EOF
)
  transformed_contents="<option value=\"$name\" data-text=\"$contents\">$name</option>"
  output+="$transformed_contents"
done

TZ=Singapore BUILD_DATE="$(date)" MORE="$output" envsubst < "$1"