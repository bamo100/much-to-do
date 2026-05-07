#!/bin/bash
set -e

echo "Deleting Kind cluster..."
Kind delete cluster --name muchtodo
echo "Cleanup complete!"