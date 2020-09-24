SCIPIO_BIN=~/git/go/src/github.com/lchsk/scipio/scipio
PROJECT_DIR=./

all: generate

generate:
	${SCIPIO_BIN} --project ${PROJECT_DIR} --build

serve:
	${SCIPIO_BIN} --project ${PROJECT_DIR} --serve