#!/bin/bash

sudo apt-get install -y docker-compose

cd nginx-rtmp && docker build -t nginx-rtmp .
