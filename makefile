DIR_IN=input_files
DIR_OUT=output_files
DIR_SRC=src
DIR_GEN=gen
PKG_SRC=src
FILE_TOM=Main
FILE_GOM=g
FILE_ANTLR=g

all: cmd_gom cmd_antlr cmd_tom 

cmd_gom: $(DIR_SRC)/$(FILE_GOM).gom 
	gom -d $(DIR_GEN) $(DIR_SRC)/$(FILE_GOM).gom
	gomantlradaptor -d $(DIR_GEN) -p $(PKG_SRC) $(DIR_SRC)/$(FILE_GOM).gom
	
cmd_antlr: $(DIR_SRC)/$(FILE_ANTLR).g
	java org.antlr.Tool -o $(DIR_GEN) -lib $(DIR_GEN)/$(PKG_SRC)/$(FILE_GOM)/ $(DIR_SRC)/$(FILE_ANTLR).g

cmd_tom: $(DIR_SRC)/$(FILE_TOM).t
	tom -d $(DIR_GEN) $(DIR_SRC)/$(FILE_TOM).t

clean:
	rm -r $(DIR_GEN)
	rm -r $(DIR_OUT)/*