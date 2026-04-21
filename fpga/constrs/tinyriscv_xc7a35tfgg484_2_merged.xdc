# AX7035 constraints for current rtl/soc/tinyriscv_soc_top.v
# Sources:
# - AX7035开发板用户手册REV1.1.pdf
# - 黑金AX7035开发板原理图.pdf
# Strategy:
# - Use board-native resources where they exist: clock, reset, UART, LEDs, SD, keys.
# - Use documented expansion header pins for ports not natively present on the board.
# Notes:
# - gpio[1:0] and jtag_* are mapped to J9 expansion header pins.
# - spi_* is mapped to the onboard MicroSD socket in SPI mode.

# Clock 50MHz
set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports {clk}]
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports {clk}]

# Reset button
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property PACKAGE_PIN F20 [get_ports rst]

# Status outputs
# User LEDs are active low on AX7035.
# Mapping three SoC status signals to three user LEDs.
set_property IOSTANDARD LVCMOS33 [get_ports over]
set_property PACKAGE_PIN E21 [get_ports over]

set_property IOSTANDARD LVCMOS33 [get_ports succ]
set_property PACKAGE_PIN F19 [get_ports succ]

set_property IOSTANDARD LVCMOS33 [get_ports halted_ind]
set_property PACKAGE_PIN D20 [get_ports halted_ind]

# UART / debug
# uart_debug_pin is tied to KEY1 on this board.
# KEY1 is active low, so the signal is high when released.
set_property IOSTANDARD LVCMOS33 [get_ports uart_debug_pin]
set_property PACKAGE_PIN M13 [get_ports uart_debug_pin]

set_property IOSTANDARD LVCMOS33 [get_ports uart_tx_pin]
set_property PACKAGE_PIN G16 [get_ports uart_tx_pin]

set_property IOSTANDARD LVCMOS33 [get_ports uart_rx_pin]
set_property PACKAGE_PIN G15 [get_ports uart_rx_pin]

# GPIO
# Mapped to J9 expansion header pins 3/4.
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[0]}]
set_property PACKAGE_PIN D16 [get_ports {gpio[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {gpio[1]}]
set_property PACKAGE_PIN E16 [get_ports {gpio[1]}]

# JTAG
# Mapped to J9 expansion header pins 5/6/7/8 for external debug hookup.
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TCK]
set_property PACKAGE_PIN F14 [get_ports jtag_TCK]

# create_clock -name jtag_clk_pin -period 300 [get_ports {jtag_TCK}]

set_property IOSTANDARD LVCMOS33 [get_ports jtag_TMS]
set_property PACKAGE_PIN F13 [get_ports jtag_TMS]

set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDI]
set_property PACKAGE_PIN E14 [get_ports jtag_TDI]

set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDO]
set_property PACKAGE_PIN E13 [get_ports jtag_TDO]

# SPI
# Mapped to onboard MicroSD socket in SPI mode:
# spi_clk  -> SD_CLK  (N15)
# spi_mosi -> SD_CMD  (P15)
# spi_miso -> SD_DAT0 (P16)
# spi_ss   -> SD_DAT3 (N13)
set_property IOSTANDARD LVCMOS33 [get_ports spi_miso]
set_property PACKAGE_PIN P16 [get_ports spi_miso]

set_property IOSTANDARD LVCMOS33 [get_ports spi_mosi]
set_property PACKAGE_PIN P15 [get_ports spi_mosi]

set_property IOSTANDARD LVCMOS33 [get_ports spi_ss]
set_property PACKAGE_PIN N13 [get_ports spi_ss]

set_property IOSTANDARD LVCMOS33 [get_ports spi_clk]
set_property PACKAGE_PIN N15 [get_ports spi_clk]

# Configuration settings
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
