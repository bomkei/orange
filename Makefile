TARGET		= orange

INCLUDES	= include
SOURCES		= src
SUBDIRS		=
BUILD			= build

COMMON		= -O2
CFLAGS		= $(COMMON) $(INCLUDE) -Wno-switch
CXXFLAGS	= $(CFLAGS) -std=c++20
LDFLAGS		= -Wl,--gc-sections

%.o: %.c
	@echo $(notdir $<)
	@clang -MP -MMD -MF $*.d $(CFLAGS) -c -o $@ $<

%.o: %.cc
	@echo $(notdir $<)
	@clang++ -MP -MMD -MF $*.d $(CXXFLAGS) -c -o $@ $<

ifneq ($(notdir $(CURDIR)), $(BUILD))

SRCDIRS		= $(SOURCES) $(foreach dir,$(SUBDIRS),$(SOURCES)/$(dir))
CFILES		= $(foreach dir,$(SRCDIRS),$(notdir $(wildcard $(dir)/*.c)))
CXXFILES	= $(foreach dir,$(SRCDIRS),$(notdir $(wildcard $(dir)/*.cc)))

export VPATH		= $(CURDIR)/$(SOURCES) $(foreach dir,$(SUBDIRS),$(CURDIR)/$(SOURCES)/$(dir))
export OFILES		= $(CFILES:.c=.o) $(CXXFILES:.cc=.o)
export OUTPUT		= $(CURDIR)/$(TARGET)
export INCLUDE	= $(foreach dir,$(INCLUDES),-I $(CURDIR)/$(dir))

all: $(BUILD)
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

debug: $(BUILD)
	@$(MAKE) --no-print-directory COMMONFLAGS="-O0 -g" LDFLAGS="" -C $(BUILD) -f $(CURDIR)/Makefile

clean:
	@rm -rf $(BUILD)
	@rm -f $(TARGET)

re: clean all

$(BUILD):
	@[ -d $@ ] || mkdir -p $@

else

DEPENDS	= $(OFILES:.o=.d)

$(OUTPUT): $(OFILES)
	@echo linking...
	@clang++ $(LDFLAGS) -o $@ $^

-include $(DEPENDS)

endif

