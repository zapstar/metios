# The main Makefile for MetiOS
all: boot

# Invoke make on boot loader
boot:
	cd boot && $(MAKE)

# Cleanup
clean:
	cd bin && $(MAKE)
