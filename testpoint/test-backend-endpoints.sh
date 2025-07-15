#!/bin/bash

# Configuration
# Usage: ./test-backend-endpoints.sh [BASE_URL]
# BASE_URL can also be set via the BACKEND_URL environment variable
BASE_URL="${1:-${BACKEND_URL:-http://localhost:7070/api}}"

# Function to test an endpoint
function test_endpoint() {
    local endpoint=$1
    local expected_status=$2
    local description=$3
    
    echo "Testing: $description"
    echo "Endpoint: $endpoint"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint")
    if [ "$response" -eq "$expected_status" ]; then
        echo " Success: Got expected status $response"
        return 0
    else
        echo " Failed: Expected $expected_status, got $response"
        echo "=== Detailed request ==="
        curl -v "$endpoint"
        echo "=== TESTS ABORTED ==="
        echo "Test failed at: $endpoint"
        echo "Expected status: $expected_status, received: $response"
        exit 1
    fi
}

# First check if the server is healthy
# If health check fails, no point in continuing with other tests
echo "=== Starting backend endpoint tests ==="
echo "Base URL: $BASE_URL"
echo "=== Testing Health Endpoint ==="
test_endpoint "${BASE_URL%/api}/health" 200 "/health endpoint (should return 200 OK)"

# Function to URL-encode a string
function url_encode() {
    local string="$1"
    local encoded_string=""
    local char
    for (( i=0; i<${#string}; i++ )); do
        char="${string:$i:1}"
        case "$char" in
            [a-zA-Z0-9.~_/-]) encoded_string+="$char" ;;
            ' ') encoded_string+="%20" ;;
            *) printf -v 'char_encoded' '%%%02X' "'$char"
               encoded_string+="$char_encoded" ;;
        esac
    done
    echo "$encoded_string"
}

# Function to get folders from structure
function get_folders() {
    local endpoint=$1
    # Log to stderr to avoid capture by command substitution
    echo "Getting folders from $endpoint..." >&2
    response=$(curl -s "$endpoint")
    
    if [ -z "$response" ]; then
        echo "✗ Error: Empty response from $endpoint" >&2
        exit 1
    fi
    
    # Extract folder paths using a more robust method
    folders=$(echo "$response" | 
        grep -oP '"items":\[\K.*(?=\])' | # Isolate the content of the "items" array
        sed 's/},{/}\n{/g' |             # Split each JSON object onto a new line
        grep '"isDirectory":true' |      # Filter for lines that represent directories
        grep -oP '"path":"\K[^"]+' |   # Extract the value of the "path" key
        tr '[:upper:]' '[:lower:]' |    # Convert to lowercase for consistency
        sort -u)                         # Sort and remove duplicates
    
    if [ -z "$folders" ]; then
        echo "✗ Error: No folders found in response" >&2
        echo "=== Raw response ===" >&2
        echo "$response" >&2
        echo "=== End of response ===" >&2
        exit 1
    fi
    
    echo "Found folders:" >&2
    echo "$folders" >&2
    # Return ONLY the folder list to stdout
    echo "$folders"

    # If folders is still empty, exit now.
    if [ -z "$folders" ]; then
        exit 1
    fi
}

# Function to get first document path
function get_first_document_path() {
    local endpoint=$1
    # Log to stderr to avoid capture by command substitution
    echo "Getting first document from $endpoint..." >&2
    response=$(curl -s "$endpoint")
    
    echo "Response: $response" >&2

    if [ -z "$response" ]; then
        echo " Error: Empty response from $endpoint"
        return 1
    fi
    
    # Extract path from JSON response, expecting {"path": "..."}
    doc_path=$(echo "$response" | grep -oP '"path":\s*"\K[^"]+' | head -n 1)
    
    if [ -z "$doc_path" ]; then
        echo "- Warning: No document found in folder. Skipping content and related tests for this folder." >&2
        return 1
    fi
    
    echo "$doc_path"
    return 0
}

# Main test function
echo "=== Starting backend endpoint tests ==="
echo "Base URL: $BASE_URL"

# 1. Test root structure and get folders
echo "\n=== Testing root structure and getting folders ==="
test_endpoint "$BASE_URL/structure/" 200 "Root directory structure"
folders=$(get_folders "$BASE_URL/structure/")

# 2. Test each folder's structure
for folder in $folders; do
    echo "=== Testing folder structure: $folder ==="
    test_endpoint "$BASE_URL/structure/$folder" 200 "Folder structure: $folder"
    
    # 3. Test first document in folder
    echo "=== Testing first document in folder: $folder ==="
    first_doc_endpoint="$BASE_URL/first-document/$folder"
    doc_path=$(get_first_document_path "$first_doc_endpoint")
    
    if [ $? -eq 0 ]; then
        # URL-encode the path to handle spaces and special characters
        encoded_doc_path=$(url_encode "$doc_path")

        # 4. Test content endpoint
        echo "=== Testing content endpoint for: $doc_path ==="
        test_endpoint "$BASE_URL/content/$encoded_doc_path" 200 "Content file: $doc_path"
        
        # 5. Test related documents
        echo "=== Testing related documents for: $doc_path ==="
        test_endpoint "$BASE_URL/related?path=$encoded_doc_path" 200 "Related documents"
        test_endpoint "$BASE_URL/related?path=$encoded_doc_path&limit=3" 200 "Related documents with limit"
        test_endpoint "$BASE_URL/related?path=$encoded_doc_path&skipCache=true" 200 "Related documents without cache"
    fi
done

