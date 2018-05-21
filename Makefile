
include $(RTE_SDK)/mk/rte.vars.mk

ifeq ($(CONFIG_RTE_LIBRTE_PDUMP), y)

APP = dpdk-pdump-qat

CFLAGS += $(WERROR_FLAGS)

QAT_INCLUDE	= -I$(ICP_ROOT)/quickassist/include		\
			  -I$(ICP_ROOT)/quickassist/include/dc 	\
			  -I$(ICP_ROOT)/quickassist/lookaside/access_layer/include
USDM_INCLUDE 	= -I$(ICP_ROOT)/quickassist/utilities/libusdm_drv
QATZIP_INCLUDE 	= -I$(QATZIP_ROOT)/include

EXTRA_CFLAGS += $(QAT_INCLUDE) $(USDM_INCLUDE) $(QATZIP_INCLUDE)
EXTRA_LDLIBS += -lqatzip

# all source are stored in SRCS-y

SRCS-y := main.c

include $(RTE_SDK)/mk/rte.app.mk

endif
