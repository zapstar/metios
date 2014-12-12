# The main Makefile for MetiOS
all: boot

# Invoke make on boot loader
boot:
	$(MAKE) -c boot

# Run the operating system
run:
	bochs

# Cleanup
clean:
	$(MAKE) -c clean
