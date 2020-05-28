# VCGen

Verification Condition Generator


## **ANTLR**

`sudo curl -O http://www.antlr.org/download/antlr-4.5.1-complete.jar`


## **TOM**

`sudo curl -O https://gforge.inria.fr/frs/download.php/file/32253/tom-2.10.tar.gz`

`tar -zxvf tom-2.10.tar.gz`


## Configure **ANTLR** and **TOM**

`chmod +x run.sh`

`./run.sh`


## Compile

`make all`

`javac gen/src/Main.java`


## Run

`java gen/src/Main input_files/<FILE_NAME>.sl`

`dot -Tpng output_files/<FILE_NAME>.dot -o output_files/<FILE_NAME>.png`
