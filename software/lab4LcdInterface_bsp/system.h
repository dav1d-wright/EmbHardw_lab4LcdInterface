/*
 * system.h - SOPC Builder system and BSP software package information
 *
 * Machine generated for CPU 'CPU' in SOPC Builder design 'systemFile'
 * SOPC Builder design path: ../../systemFile.sopcinfo
 *
 * Generated: Tue Oct 31 22:43:36 CET 2017
 */

/*
 * DO NOT MODIFY THIS FILE
 *
 * Changing this file will have subtle consequences
 * which will almost certainly lead to a nonfunctioning
 * system. If you do modify this file, be aware that your
 * changes will be overwritten and lost when this file
 * is generated again.
 *
 * DO NOT MODIFY THIS FILE
 */

/*
 * License Agreement
 *
 * Copyright (c) 2008
 * Altera Corporation, San Jose, California, USA.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * This agreement shall be governed in all respects by the laws of the State
 * of California and by the laws of the United States of America.
 */

#ifndef __SYSTEM_H_
#define __SYSTEM_H_

/* Include definitions from linker script generator */
#include "linker.h"


/*
 * CPU configuration
 *
 */

#define ALT_CPU_ARCHITECTURE "altera_nios2_gen2"
#define ALT_CPU_BIG_ENDIAN 0
#define ALT_CPU_BREAK_ADDR 0x02002820
#define ALT_CPU_CPU_ARCH_NIOS2_R1
#define ALT_CPU_CPU_FREQ 50000000u
#define ALT_CPU_CPU_ID_SIZE 1
#define ALT_CPU_CPU_ID_VALUE 0x00000000
#define ALT_CPU_CPU_IMPLEMENTATION "fast"
#define ALT_CPU_DATA_ADDR_WIDTH 0x1a
#define ALT_CPU_DCACHE_BYPASS_MASK 0x80000000
#define ALT_CPU_DCACHE_LINE_SIZE 32
#define ALT_CPU_DCACHE_LINE_SIZE_LOG2 5
#define ALT_CPU_DCACHE_SIZE 2048
#define ALT_CPU_EXCEPTION_ADDR 0x02000020
#define ALT_CPU_FLASH_ACCELERATOR_LINES 0
#define ALT_CPU_FLASH_ACCELERATOR_LINE_SIZE 0
#define ALT_CPU_FLUSHDA_SUPPORTED
#define ALT_CPU_FREQ 50000000
#define ALT_CPU_HARDWARE_DIVIDE_PRESENT 0
#define ALT_CPU_HARDWARE_MULTIPLY_PRESENT 1
#define ALT_CPU_HARDWARE_MULX_PRESENT 0
#define ALT_CPU_HAS_DEBUG_CORE 1
#define ALT_CPU_HAS_DEBUG_STUB
#define ALT_CPU_HAS_EXTRA_EXCEPTION_INFO
#define ALT_CPU_HAS_ILLEGAL_INSTRUCTION_EXCEPTION
#define ALT_CPU_HAS_JMPI_INSTRUCTION
#define ALT_CPU_ICACHE_LINE_SIZE 32
#define ALT_CPU_ICACHE_LINE_SIZE_LOG2 5
#define ALT_CPU_ICACHE_SIZE 4096
#define ALT_CPU_INITDA_SUPPORTED
#define ALT_CPU_INST_ADDR_WIDTH 0x1a
#define ALT_CPU_NAME "CPU"
#define ALT_CPU_NUM_OF_SHADOW_REG_SETS 0
#define ALT_CPU_OCI_VERSION 1
#define ALT_CPU_RESET_ADDR 0x01000000


/*
 * CPU configuration (with legacy prefix - don't use these anymore)
 *
 */

#define NIOS2_BIG_ENDIAN 0
#define NIOS2_BREAK_ADDR 0x02002820
#define NIOS2_CPU_ARCH_NIOS2_R1
#define NIOS2_CPU_FREQ 50000000u
#define NIOS2_CPU_ID_SIZE 1
#define NIOS2_CPU_ID_VALUE 0x00000000
#define NIOS2_CPU_IMPLEMENTATION "fast"
#define NIOS2_DATA_ADDR_WIDTH 0x1a
#define NIOS2_DCACHE_BYPASS_MASK 0x80000000
#define NIOS2_DCACHE_LINE_SIZE 32
#define NIOS2_DCACHE_LINE_SIZE_LOG2 5
#define NIOS2_DCACHE_SIZE 2048
#define NIOS2_EXCEPTION_ADDR 0x02000020
#define NIOS2_FLASH_ACCELERATOR_LINES 0
#define NIOS2_FLASH_ACCELERATOR_LINE_SIZE 0
#define NIOS2_FLUSHDA_SUPPORTED
#define NIOS2_HARDWARE_DIVIDE_PRESENT 0
#define NIOS2_HARDWARE_MULTIPLY_PRESENT 1
#define NIOS2_HARDWARE_MULX_PRESENT 0
#define NIOS2_HAS_DEBUG_CORE 1
#define NIOS2_HAS_DEBUG_STUB
#define NIOS2_HAS_EXTRA_EXCEPTION_INFO
#define NIOS2_HAS_ILLEGAL_INSTRUCTION_EXCEPTION
#define NIOS2_HAS_JMPI_INSTRUCTION
#define NIOS2_ICACHE_LINE_SIZE 32
#define NIOS2_ICACHE_LINE_SIZE_LOG2 5
#define NIOS2_ICACHE_SIZE 4096
#define NIOS2_INITDA_SUPPORTED
#define NIOS2_INST_ADDR_WIDTH 0x1a
#define NIOS2_NUM_OF_SHADOW_REG_SETS 0
#define NIOS2_OCI_VERSION 1
#define NIOS2_RESET_ADDR 0x01000000


/*
 * Define for each module class mastered by the CPU
 *
 */

#define __ALTERA_AVALON_JTAG_UART
#define __ALTERA_AVALON_NEW_SDRAM_CONTROLLER
#define __ALTERA_AVALON_ONCHIP_MEMORY2
#define __ALTERA_AVALON_PERFORMANCE_COUNTER
#define __ALTERA_AVALON_SYSID_QSYS
#define __ALTERA_AVALON_TIMER
#define __ALTERA_NIOS2_GEN2
#define __ALTPLL
#define __LCD


/*
 * LCD configuration
 *
 */

#define ALT_MODULE_CLASS_LCD LCD
#define LCD_BASE 0x20030c0
#define LCD_IRQ -1
#define LCD_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LCD_NAME "/dev/LCD"
#define LCD_SPAN 16
#define LCD_TYPE "LCD"


/*
 * SDRAM_ctrl configuration
 *
 */

#define ALT_MODULE_CLASS_SDRAM_ctrl altera_avalon_new_sdram_controller
#define SDRAM_CTRL_BASE 0x1000000
#define SDRAM_CTRL_CAS_LATENCY 3
#define SDRAM_CTRL_CONTENTS_INFO
#define SDRAM_CTRL_INIT_NOP_DELAY 0.0
#define SDRAM_CTRL_INIT_REFRESH_COMMANDS 2
#define SDRAM_CTRL_IRQ -1
#define SDRAM_CTRL_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SDRAM_CTRL_IS_INITIALIZED 1
#define SDRAM_CTRL_NAME "/dev/SDRAM_ctrl"
#define SDRAM_CTRL_POWERUP_DELAY 100.0
#define SDRAM_CTRL_REFRESH_PERIOD 15.625
#define SDRAM_CTRL_REGISTER_DATA_IN 1
#define SDRAM_CTRL_SDRAM_ADDR_WIDTH 0x17
#define SDRAM_CTRL_SDRAM_BANK_WIDTH 2
#define SDRAM_CTRL_SDRAM_COL_WIDTH 9
#define SDRAM_CTRL_SDRAM_DATA_WIDTH 16
#define SDRAM_CTRL_SDRAM_NUM_BANKS 4
#define SDRAM_CTRL_SDRAM_NUM_CHIPSELECTS 1
#define SDRAM_CTRL_SDRAM_ROW_WIDTH 12
#define SDRAM_CTRL_SHARED_DATA 0
#define SDRAM_CTRL_SIM_MODEL_BASE 0
#define SDRAM_CTRL_SPAN 16777216
#define SDRAM_CTRL_STARVATION_INDICATOR 0
#define SDRAM_CTRL_TRISTATE_BRIDGE_SLAVE ""
#define SDRAM_CTRL_TYPE "altera_avalon_new_sdram_controller"
#define SDRAM_CTRL_T_AC 5.5
#define SDRAM_CTRL_T_MRD 3
#define SDRAM_CTRL_T_RCD 20.0
#define SDRAM_CTRL_T_RFC 70.0
#define SDRAM_CTRL_T_RP 20.0
#define SDRAM_CTRL_T_WR 14.0


/*
 * System configuration
 *
 */

#define ALT_DEVICE_FAMILY "Cyclone IV E"
#define ALT_ENHANCED_INTERRUPT_API_PRESENT
#define ALT_IRQ_BASE NULL
#define ALT_LOG_PORT "/dev/null"
#define ALT_LOG_PORT_BASE 0x0
#define ALT_LOG_PORT_DEV null
#define ALT_LOG_PORT_TYPE ""
#define ALT_NUM_EXTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERNAL_INTERRUPT_CONTROLLERS 1
#define ALT_NUM_INTERRUPT_CONTROLLERS 1
#define ALT_STDERR "/dev/jtag_uart"
#define ALT_STDERR_BASE 0x20030e0
#define ALT_STDERR_DEV jtag_uart
#define ALT_STDERR_IS_JTAG_UART
#define ALT_STDERR_PRESENT
#define ALT_STDERR_TYPE "altera_avalon_jtag_uart"
#define ALT_STDIN "/dev/jtag_uart"
#define ALT_STDIN_BASE 0x20030e0
#define ALT_STDIN_DEV jtag_uart
#define ALT_STDIN_IS_JTAG_UART
#define ALT_STDIN_PRESENT
#define ALT_STDIN_TYPE "altera_avalon_jtag_uart"
#define ALT_STDOUT "/dev/jtag_uart"
#define ALT_STDOUT_BASE 0x20030e0
#define ALT_STDOUT_DEV jtag_uart
#define ALT_STDOUT_IS_JTAG_UART
#define ALT_STDOUT_PRESENT
#define ALT_STDOUT_TYPE "altera_avalon_jtag_uart"
#define ALT_SYSTEM_NAME "systemFile"


/*
 * TCDM configuration
 *
 */

#define ALT_MODULE_CLASS_TCDM altera_avalon_onchip_memory2
#define TCDM_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define TCDM_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define TCDM_BASE 0x2001000
#define TCDM_CONTENTS_INFO ""
#define TCDM_DUAL_PORT 0
#define TCDM_GUI_RAM_BLOCK_TYPE "AUTO"
#define TCDM_INIT_CONTENTS_FILE "systemFile_TCDM"
#define TCDM_INIT_MEM_CONTENT 1
#define TCDM_INSTANCE_ID "NONE"
#define TCDM_IRQ -1
#define TCDM_IRQ_INTERRUPT_CONTROLLER_ID -1
#define TCDM_NAME "/dev/TCDM"
#define TCDM_NON_DEFAULT_INIT_FILE_ENABLED 0
#define TCDM_RAM_BLOCK_TYPE "AUTO"
#define TCDM_READ_DURING_WRITE_MODE "DONT_CARE"
#define TCDM_SINGLE_CLOCK_OP 0
#define TCDM_SIZE_MULTIPLE 1
#define TCDM_SIZE_VALUE 4096
#define TCDM_SPAN 4096
#define TCDM_TYPE "altera_avalon_onchip_memory2"
#define TCDM_WRITABLE 1


/*
 * TCIM configuration
 *
 */

#define ALT_MODULE_CLASS_TCIM altera_avalon_onchip_memory2
#define TCIM_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define TCIM_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define TCIM_BASE 0x2000000
#define TCIM_CONTENTS_INFO ""
#define TCIM_DUAL_PORT 1
#define TCIM_GUI_RAM_BLOCK_TYPE "AUTO"
#define TCIM_INIT_CONTENTS_FILE "systemFile_TCIM"
#define TCIM_INIT_MEM_CONTENT 1
#define TCIM_INSTANCE_ID "NONE"
#define TCIM_IRQ -1
#define TCIM_IRQ_INTERRUPT_CONTROLLER_ID -1
#define TCIM_NAME "/dev/TCIM"
#define TCIM_NON_DEFAULT_INIT_FILE_ENABLED 0
#define TCIM_RAM_BLOCK_TYPE "AUTO"
#define TCIM_READ_DURING_WRITE_MODE "DONT_CARE"
#define TCIM_SINGLE_CLOCK_OP 0
#define TCIM_SIZE_MULTIPLE 1
#define TCIM_SIZE_VALUE 4096
#define TCIM_SPAN 4096
#define TCIM_TYPE "altera_avalon_onchip_memory2"
#define TCIM_WRITABLE 1


/*
 * altpll_0 configuration
 *
 */

#define ALTPLL_0_BASE 0x20030b0
#define ALTPLL_0_IRQ -1
#define ALTPLL_0_IRQ_INTERRUPT_CONTROLLER_ID -1
#define ALTPLL_0_NAME "/dev/altpll_0"
#define ALTPLL_0_SPAN 16
#define ALTPLL_0_TYPE "altpll"
#define ALT_MODULE_CLASS_altpll_0 altpll


/*
 * altpll_signalTap configuration
 *
 */

#define ALTPLL_SIGNALTAP_BASE 0x20030a0
#define ALTPLL_SIGNALTAP_IRQ -1
#define ALTPLL_SIGNALTAP_IRQ_INTERRUPT_CONTROLLER_ID -1
#define ALTPLL_SIGNALTAP_NAME "/dev/altpll_signalTap"
#define ALTPLL_SIGNALTAP_SPAN 16
#define ALTPLL_SIGNALTAP_TYPE "altpll"
#define ALT_MODULE_CLASS_altpll_signalTap altpll


/*
 * hal configuration
 *
 */

#define ALT_INCLUDE_INSTRUCTION_RELATED_EXCEPTION_API
#define ALT_MAX_FD 32
#define ALT_SYS_CLK TIMER_0
#define ALT_TIMESTAMP_CLK none


/*
 * jtag_uart configuration
 *
 */

#define ALT_MODULE_CLASS_jtag_uart altera_avalon_jtag_uart
#define JTAG_UART_BASE 0x20030e0
#define JTAG_UART_IRQ 0
#define JTAG_UART_IRQ_INTERRUPT_CONTROLLER_ID 0
#define JTAG_UART_NAME "/dev/jtag_uart"
#define JTAG_UART_READ_DEPTH 64
#define JTAG_UART_READ_THRESHOLD 8
#define JTAG_UART_SPAN 8
#define JTAG_UART_TYPE "altera_avalon_jtag_uart"
#define JTAG_UART_WRITE_DEPTH 64
#define JTAG_UART_WRITE_THRESHOLD 8


/*
 * performance_counter_0 configuration
 *
 */

#define ALT_MODULE_CLASS_performance_counter_0 altera_avalon_performance_counter
#define PERFORMANCE_COUNTER_0_BASE 0x2003000
#define PERFORMANCE_COUNTER_0_HOW_MANY_SECTIONS 7
#define PERFORMANCE_COUNTER_0_IRQ -1
#define PERFORMANCE_COUNTER_0_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PERFORMANCE_COUNTER_0_NAME "/dev/performance_counter_0"
#define PERFORMANCE_COUNTER_0_SPAN 128
#define PERFORMANCE_COUNTER_0_TYPE "altera_avalon_performance_counter"


/*
 * sysid configuration
 *
 */

#define ALT_MODULE_CLASS_sysid altera_avalon_sysid_qsys
#define SYSID_BASE 0x20030d8
#define SYSID_ID 0
#define SYSID_IRQ -1
#define SYSID_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SYSID_NAME "/dev/sysid"
#define SYSID_SPAN 8
#define SYSID_TIMESTAMP 1509485925
#define SYSID_TYPE "altera_avalon_sysid_qsys"


/*
 * timer_0 configuration
 *
 */

#define ALT_MODULE_CLASS_timer_0 altera_avalon_timer
#define TIMER_0_ALWAYS_RUN 0
#define TIMER_0_BASE 0x2003080
#define TIMER_0_COUNTER_SIZE 32
#define TIMER_0_FIXED_PERIOD 1
#define TIMER_0_FREQ 50000000
#define TIMER_0_IRQ 1
#define TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID 0
#define TIMER_0_LOAD_VALUE 499999
#define TIMER_0_MULT 0.001
#define TIMER_0_NAME "/dev/timer_0"
#define TIMER_0_PERIOD 10
#define TIMER_0_PERIOD_UNITS "ms"
#define TIMER_0_RESET_OUTPUT 0
#define TIMER_0_SNAPSHOT 1
#define TIMER_0_SPAN 32
#define TIMER_0_TICKS_PER_SEC 100
#define TIMER_0_TIMEOUT_PULSE_OUTPUT 0
#define TIMER_0_TYPE "altera_avalon_timer"

#endif /* __SYSTEM_H_ */
