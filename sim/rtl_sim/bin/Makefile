
all:	sim
SHELL = /bin/sh
MS="-s"

##########################################################################
#
# DUT Sources
#
##########################################################################
DUT_SRC_DIR=../../../rtl/verilog
_TARGETS_=	$(DUT_SRC_DIR)/ac97_top.v                      \
		$(DUT_SRC_DIR)/ac97_sout.v                     \
		$(DUT_SRC_DIR)/ac97_sin.v                      \
		$(DUT_SRC_DIR)/ac97_soc.v                      \
		$(DUT_SRC_DIR)/ac97_out_fifo.v                 \
		$(DUT_SRC_DIR)/ac97_in_fifo.v                  \
		$(DUT_SRC_DIR)/ac97_wb_if.v                    \
		$(DUT_SRC_DIR)/ac97_rf.v                       \
		$(DUT_SRC_DIR)/ac97_prc.v                      \
		$(DUT_SRC_DIR)/ac97_fifo_ctrl.v                \
		$(DUT_SRC_DIR)/ac97_cra.v                      \
		$(DUT_SRC_DIR)/ac97_dma_if.v                   \
		$(DUT_SRC_DIR)/ac97_dma_req.v                  \
		$(DUT_SRC_DIR)/ac97_int.v                      \
		$(DUT_SRC_DIR)/ac97_rst.v 

##########################################################################
#
# Test Bench Sources
#
##########################################################################
_TOP_=test
TB_SRC_DIR=../../../bench/verilog
_TB_=		$(TB_SRC_DIR)/ac97_codec_sout.v            \
		$(TB_SRC_DIR)/ac97_codec_sin.v             \
		$(TB_SRC_DIR)/ac97_codec_top.v             \
		$(TB_SRC_DIR)/test_bench_top.v             \
		$(TB_SRC_DIR)/wb_mast_model.v 

##########################################################################
#
# Misc Variables
#
##########################################################################

INCDIR="-INCDIR ./$(DUT_SRC_DIR)/ -INCDIR ./$(TB_SRC_DIR)/"
LOGF=-LOGFILE .nclog
NCCOMMON=-CDSLIB ncwork/cds.lib -HDLVAR ncwork/hdl.var -NOCOPYRIGHT

##########################################################################
#
# Make Targets
#
##########################################################################
simw:
	@$(MAKE) -s sim ACCESS="-ACCESS +r " WAVES="-DEFINE WAVES"

ss:
	signalscan -do waves/waves.do -waves waves/waves.trn &

simxl:
	verilog +incdir+$(DUT_SRC_DIR) +incdir+$(TB_SRC_DIR)	\
	$(_TARGETS_) $(_TB_)

sim:
	@echo ""
	@echo "----- Running NCVLOG ... ----------"
	@$(MAKE) $(MS) vlog				\
		TARGETS="$(_TARGETS_)"			\
		TB="$(_TB_)"				\
		INCDIR=$(INCDIR)			\
		WAVES="$(WAVES)"
	@echo ""
	@echo "----- Running NCELAB ... ----------"
	@$(MAKE) $(MS) elab				\
		ACCESS="$(ACCESS)" TOP=$(_TOP_)
	@echo ""
	@echo "----- Running NCSIM ... ----------"
	@$(MAKE) $(MS) ncsim TOP=$(_TOP_)
	@echo ""

hal:
	@echo ""
	@echo "----- Running HAL ... ----------"
	@hal    +incdir+$(DUT_SRC_DIR)				\
		-NOP -NOS -nocheck STYVAL:USEPRT:NOBLKN:DLNBLK	\
		$(_TARGETS_)
	@echo "----- DONE ... ----------"

clean:
	rm -rf	./waves/*.dsn ./waves/*.trn		\
		ncwork/.inc* ncwork/inc*		\
		./verilog.* .nclog hal.log

##########################################################################
#
# NCVLOG
#
##########################################################################

vhdl:
	ncvhdl $(NCCOMMON) $(LOGF) -APPEND_LOG			\
		-WORK count -V93 hdl/counter.vhd
	ncvhdl $(NCCOMMON) $(LOGF) -APPEND_LOG			\
		-WORK work -V93 $(TARGETS)

vlog:
	ncvlog $(NCCOMMON) $(LOGF) 				\
		-WORK work $(WAVES) $(TB) $(TARGETS) $(INCDIR)

##########################################################################
#
# NCELAB
#
##########################################################################

elab:
	ncelab	$(NCCOMMON) $(LOGF) -APPEND_LOG 		\
		-WORK work $(ACCESS) -NOTIMINGCHECKS		\
		work.$(TOP)

##########################################################################
#
# NCSIM
#
##########################################################################

ncsim:
	ncsim	$(NCCOMMON) $(LOGF) -APPEND_LOG			\
		-EXIT -ERRORMAX 10 work.$(TOP)


