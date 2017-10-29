/*
 * main.c
 *
 *  Created on: 02.10.2017
 *      Author: z003nc3v
 */

#include <stdio.h>
#include <stdbool.h>
#include "io.h"
#include "system.h"
#include "alt_types.h"
#include "sys/alt_irq.h"
#include "priv/alt_legacy_irq.h"
#include "altera_avalon_timer_regs.h"
#include "altera_avalon_performance_counter.h"

#define CLEAR_IRQ 0x0000
#define COUNT_MAX 1000
#define PERFORMANCE_COUNTER_SEG_ISR 1

typedef struct Counter {
	alt_u32 value;
	bool isNew;
} Counter;

__attribute__((section(".exceptions")))static void handle_timerIRQ(
		void* context, alt_u32 id);
static void initPioLeds(void);

int main(void) {
	Counter downTimer = { .value = 0, .isNew = false };

	alt_irq_context statusISR;

	puts("Reset performance counter");
	PERF_RESET(PERFORMANCE_COUNTER_0_BASE);

	puts("IRQs disabled.");
	statusISR = alt_irq_disable_all();

	puts("Register timer IRQ handler...");
	alt_irq_register(TIMER_0_IRQ, &downTimer, (alt_isr_func) handle_timerIRQ);

	puts("Clear pending timer IRQs...");
	IOWR_16DIRECT(TIMER_0_BASE, ALTERA_AVALON_TIMER_STATUS_REG, CLEAR_IRQ);

	puts("Init PIO LEDs");
	initPioLeds();

	puts("Configure timer...");
	IOWR_16DIRECT(TIMER_0_BASE, ALTERA_AVALON_TIMER_CONTROL_REG,
			ALTERA_AVALON_TIMER_CONTROL_ITO_MSK
					| ALTERA_AVALON_TIMER_CONTROL_CONT_MSK
					| ALTERA_AVALON_TIMER_CONTROL_START_MSK);

	puts("Timer initialised and started!");

	puts("Start measuring with performance counter");
	PERF_START_MEASURING(PERFORMANCE_COUNTER_0_BASE);

	puts("Enable all IRQs");
	alt_irq_enable_all(statusISR);

	while (downTimer.value < COUNT_MAX) {
		if (downTimer.isNew) {
			printf("New counter value: %lu\n", (alt_u32) downTimer.value);
			downTimer.isNew = false;
		} else {
			asm volatile("nop");
		}
	}

	puts("Stop measuring with performance counter");
	PERF_STOP_MEASURING(PERFORMANCE_COUNTER_0_BASE);
	perf_print_formatted_report(PERFORMANCE_COUNTER_0_BASE, alt_get_cpu_freq(),
			1, "ISR");
	return 0;
}

static void handle_timerIRQ(void* context, alt_u32 id) {
	PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, PERFORMANCE_COUNTER_SEG_ISR);

	Counter* data_ptr = (Counter*) context;

	(data_ptr->value)++;
	data_ptr->isNew = true;

	IOWR_8DIRECT(MYPIO_LEDS_BASE, 0x02U, data_ptr->value);
	printf("New pin value: %d\r\n", IORD_8DIRECT(MYPIO_LEDS_BASE, 0x001));
	IOWR_16DIRECT(TIMER_0_BASE, ALTERA_AVALON_TIMER_STATUS_REG, CLEAR_IRQ);
	PERF_END(PERFORMANCE_COUNTER_0_BASE, PERFORMANCE_COUNTER_SEG_ISR);
}

static void initPioLeds(void)
{
	// Configure all pins as outputs
	IOWR_8DIRECT(MYPIO_LEDS_BASE, 0, 0xFFU);
	IOWR_8DIRECT(MYPIO_LEDS_BASE, 0x02U, 0x00U);

}
