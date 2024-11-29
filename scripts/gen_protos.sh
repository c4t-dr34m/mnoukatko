#!/bin/bash

# 
# Mňoukátko - the Meshtastic® client
# 
# Copyright © 2022-2024 Blake McAnally
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# 

# simple sanity checking for repo
if [ ! -d "./protobufs" ]; then
  git submodule update --init
else 
  git submodule update --remote --merge
fi

# simple sanity checking for executable
if [ ! -x "$(which protoc)" ]; then
  brew install swift-protobuf
fi

protoc --proto_path=./protobufs --swift_opt=Visibility=Public --swift_out=./MeshtasticProtobufs/Sources ./protobufs/meshtastic/*.proto 

echo "Done generating the swift files from the proto files."
echo "Build, test, and commit changes."
