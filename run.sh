#!/bin/bash 

export TOM_HOME=/home/mjf/Desktop/TP-VF/tom-2.10
export PROJECT_HOME=/home/mjf/Desktop/TP-VF/TP-v2

export CLASSPATH=/usr/local/lib/antlr-4.5.1-complete.jar:${CLASSPATH}
alias antlr4='java -jar /usr/local/lib/antlr-4.5.1-complete.jar'
alias grun='java org.antlr.v4.gui.TestRig'

export PATH=${PATH}:${TOM_HOME}/bin
export CLASSPATH=${TOM_HOME}/lib/tom-runtime-full.jar:${CLASSPATH}