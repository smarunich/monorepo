#!/bin/bash

kubectl logs -f deploy/productpage-v2 -n bookinfo | awk '
{
    if ($0 ~ /INFO:productpage:Vendor/) {
        # Start collecting lines
        status_line = $0
        region_line = ""
        collecting = 1
    } else if (collecting) {
        # Check if the line contains "x-source-region"
        if ($0 ~ /"x-source-region":/) {
            region_line = $0
            collecting = 0  # Stop collecting

            # Process and color the lines
            # Color the status line in cyan
            status_line_colored = "\033[36m" status_line "\033[0m"

            # Extract the status code
            match(status_line, /status code ([0-9]{3})/, arr)
        if ($0 ~ /"x-source-region":/) {
            region_line = $0
            collecting = 0  # Stop collecting

            # Process and color the lines
            # Color the status line in cyan
            status_line_colored = "\033[36m" status_line "\033[0m"

            # Extract the status code
            match(status_line, /status code ([0-9]{3})/, arr)
            status_code = arr[1]

            # Determine color for status code
            if (status_code ~ /^5/) {
                status_color = "\033[31m"  # Red for 5xx errors
            } else {
                status_color = "\033[32m"  # Green for other status codes
            }

            # Color the status code within the status line
            gsub(/status code [0-9]{3}/, status_color "status code " status_code "\033[36m", status_line_colored)

            # Color the region line in blue
            region_line_colored = "\033[34m" region_line "\033[0m"

            # Print the colored lines
            print status_line_colored
            print region_line_colored
        }
    }
}
'
