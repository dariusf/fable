#!/bin/bash

files=(../examples/*.md)

for file in "${files[@]}"; do
  contents="$(sed 's/"/\&quot;/g' < "$file")"
  name=$(echo "$file" | sed -e 's/\.md//g' -e 's@../examples/@@g')
  transformed_contents="<option value=\"$name\" data-text=\"$contents\">$name</option>"
  output+="$transformed_contents"
done

TZ=Singapore BUILD_DATE="$(date)" MORE="$output" envsubst < "$1"