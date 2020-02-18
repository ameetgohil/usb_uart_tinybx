.default: all

all: build program

build:
	python -m apio build

program:
	python -m tinyprog --program ./hardware.bin
	echo "screen /dev/ttyACM0 115200"

clean:
	python -m apio clean
