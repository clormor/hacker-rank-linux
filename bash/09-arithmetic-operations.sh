#!/bin/bash

read expression
bc <<< "scale=3; $expression"
