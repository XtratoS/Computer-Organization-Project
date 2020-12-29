#! /bin/sh
iverilog Clock.v PCI.v ReadWriteTB.v -o pci_demo
./pci_demo > pci_demo.txt
