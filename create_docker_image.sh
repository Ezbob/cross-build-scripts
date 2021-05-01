#!/bin/bash

: ${IMAGE:=gcc_builder:latest}

docker build -t "${IMAGE}" .
