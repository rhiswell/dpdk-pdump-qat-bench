
include $(RTE_SDK)/mk/rte.vars.mk

ifeq ($(CONFIG_RTE_LIBRTE_PDUMP),y)

APP = dpdk-pdump-qat

CFLAGS += $(WERROR_FLAGS)

# all source are stored in SRCS-y

SRCS-y := main.c

include $(RTE_SDK)/mk/rte.app.mk

endif
