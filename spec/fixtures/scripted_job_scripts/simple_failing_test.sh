#!/bin/bash

echo "This will not work"
ls '/junkdirectory-does-not-exist/' 2> /dev/null
