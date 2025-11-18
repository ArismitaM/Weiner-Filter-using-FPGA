### ======================================================================
### Basys3 UART-only project constraints
### Board: Digilent Basys-3 (Artix-7 XC7A35T-1CPG236C)
### Function: Clock, Reset button, Bypass switch, UART TX to PC
### ======================================================================

### ------------------------------
### Clock: 100 MHz onboard oscillator
### ------------------------------
#set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
#set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
#create_clock -add -name sys_clk -period 10.000 [get_ports CLK100MHZ]

### ------------------------------
### Reset Button (Center Button, btnC)
### ------------------------------
#set_property PACKAGE_PIN U18 [get_ports RESET_BTN]
#set_property IOSTANDARD LVCMOS33 [get_ports RESET_BTN]

### ------------------------------
### Switch 0 (Used for bypass mode)
### ------------------------------
#set_property PACKAGE_PIN V17 [get_ports SW_BYPASS]
#set_property IOSTANDARD LVCMOS33 [get_ports SW_BYPASS]

### ------------------------------
### UART TX: FPGA → PC
### Connected to FTDI USB-UART bridge
### Basys3 pin JA1 = FPGA pin A18
### ------------------------------
#set_property PACKAGE_PIN A18 [get_ports UART_TXD]
#set_property IOSTANDARD LVCMOS33 [get_ports UART_TXD]

### ------------------------------
### Optional UART RX (if you ever add it)
### Connected to FTDI bridge JA2 = FPGA pin B18
### Uncomment if used
### ------------------------------
## set_property PACKAGE_PIN B18 [get_ports UART_RXD]
## set_property IOSTANDARD LVCMOS33 [get_ports UART_RXD]

### ======================================================================
### END OF FILE
### ======================================================================

## ======================================================================
## Basys3 UART-only project constraints
## Board: Digilent Basys-3 (Artix-7 XC7A35T-1CPG236C)
## Function: Clock, Reset button, Bypass switch, UART TX to PC
## ======================================================================

## ------------------------------
## Clock: 100 MHz onboard oscillator
## ------------------------------
set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -add -name sys_clk -period 10.000 [get_ports CLK100MHZ]

## ------------------------------
## Reset Button (Center Button, btnC)
## ------------------------------
set_property PACKAGE_PIN U18 [get_ports RESET_BTN]
set_property IOSTANDARD LVCMOS33 [get_ports RESET_BTN]

## ------------------------------
## Switch 0 (Used for bypass mode)
## ------------------------------
set_property PACKAGE_PIN V17 [get_ports SW_BYPASS]
set_property IOSTANDARD LVCMOS33 [get_ports SW_BYPASS]

## ------------------------------
## UART TX: FPGA → PC
## Connected to FTDI USB-UART bridge
## Basys3 pin JA1 = FPGA pin A18
## ------------------------------
set_property PACKAGE_PIN A18 [get_ports UART_TXD]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TXD]

## ------------------------------
## Optional UART RX (if you ever add it)
## Connected to FTDI bridge JA2 = FPGA pin B18
## Uncomment if used
## ------------------------------
# set_property PACKAGE_PIN B18 [get_ports UART_RXD]
# set_property IOSTANDARD LVCMOS33 [get_ports UART_RXD]

## ======================================================================
## END OF FILE
## ======================================================================

