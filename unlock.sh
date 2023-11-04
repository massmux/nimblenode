#!/bin/bash

echo "Unlock wallet .."
docker exec -ti lit /app/lncli unlock
