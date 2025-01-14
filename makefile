# vrisp
#
# @file
# @version 0.1

CXX ?= g++

FR_LIB = framework-open/lib/libframework.a
FR_INCLUDES = framework-open/include/
FR_CFLAGS = -std=c++11 -Wall -Wextra -Iframework-open/include -Iframework-open/include/utils $(CFLAGS)
FR_OBJ = framework-open/obj/framework.o framework-open/obj/processor_help.o framework-open/obj/properties.o

RISP_OBJ = framework-open/obj/risp.o framework-open/obj/risp_static.o
VRISP_OBJ = framework-open/obj/vrisp.o  framework-open/obj/vrisp_static.o
VRISP_RVV_FULL_OBJ = framework-open/obj/vrisp_rvv_full.o framework-open/obj/vrisp_static.o
VRISP_RVV_FIRED_OBJ = framework-open/obj/vrisp_rvv_fired.o framework-open/obj/vrisp_static.o
VRISP_RVV_SYNAPSES_OBJ = framework-open/obj/vrisp_rvv_synapses.o framework-open/obj/vrisp_static.o

FRAMEWORK_DIR = framework-open/
DBSCAN_DIR = dbscan/

all: dbscan/bin/dbscan_systolic_full \
	 framework-open/bin/network_tool \
	 bin/dbscan_app_risp \
	 bin/dbscan_app_vrisp \
	 bin/connectivity_app_risp \
	 bin/connectivity_app_vrisp \

riscv_vector: all \
						  bin/dbscan_app_vrisp_vector_full \
						  bin/dbscan_app_vrisp_vector_fired \
						  bin/dbscan_app_vrisp_vector_synapses \
						  bin/connectivity_app_vrisp_vector_full \
						  bin/connectivity_app_vrisp_vector_fired \
						  bin/connectivity_app_vrisp_vector_synapses

# Applications ################################################################
bin/dbscan_app_risp: src/dbscan_app.cpp $(RISP_OBJ) $(FR_LIB)
	$(CXX) $(FR_CFLAGS) -o $@ $^

bin/dbscan_app_vrisp: src/dbscan_app.cpp $(VRISP_OBJ) $(FR_LIB)
	$(CXX) $(FR_CFLAGS) -o $@ $^

bin/dbscan_app_vrisp_vector_full: src/dbscan_app.cpp $(VRISP_RVV_FULL_OBJ) $(FR_LIB)
	$(CXX) $(FR_CFLAGS) -o $@ $^

bin/dbscan_app_vrisp_vector_fired: src/dbscan_app.cpp $(VRISP_RVV_FIRED_OBJ) $(FR_LIB)
	$(CXX) $(FR_CFLAGS) -o $@ $^

bin/dbscan_app_vrisp_vector_synapses: src/dbscan_app.cpp $(VRISP_RVV_SYNAPSES_OBJ) $(FR_LIB)
	$(CXX) $(FR_CFLAGS) -o $@ $^

bin/connectivity_app_risp: src/connectivity_app.cpp $(RISP_OBJ) $(FR_LIB)
	$(CXX) $(FR_CFLAGS) -o $@ $^

bin/connectivity_app_vrisp: src/connectivity_app.cpp $(VRISP_OBJ) $(FR_LIB)
	$(CXX) $(FR_CFLAGS) -o $@ $^

bin/connectivity_app_vrisp_vector_full: src/connectivity_app.cpp $(VRISP_RVV_FULL_OBJ) $(FR_LIB)
	$(CXX) $(FR_CFLAGS) -o $@ $^

bin/connectivity_app_vrisp_vector_fired: src/connectivity_app.cpp $(VRISP_RVV_FIRED_OBJ) $(FR_LIB)
	$(CXX) $(FR_CFLAGS) -o $@ $^

bin/connectivity_app_vrisp_vector_synapses: src/connectivity_app.cpp $(VRISP_RVV_SYNAPSES_OBJ) $(FR_LIB)
	$(CXX) $(FR_CFLAGS) -o $@ $^

# Libraries ###################################################################
framework-open/lib/libframework.a: $(FR_OBJ) framework-open/include/framework.hpp
	ar r framework-open/lib/libframework.a $(FR_OBJ)
	ranlib framework-open/lib/libframework.a

# Objects #####################################################################
framework-open/obj/framework.o: framework-open/src/framework.cpp $(FR_INC)
	$(CXX) -c $(FR_CFLAGS) -o $@ framework-open/src/framework.cpp

framework-open/obj/processor_help.o: framework-open/src/processor_help.cpp $(FR_INC)
	$(CXX) -c $(FR_CFLAGS) -o framework-open/obj/processor_help.o framework-open/src/processor_help.cpp

framework-open/obj/properties.o: framework-open/src/properties.cpp $(FR_INC)
	$(CXX) -c $(FR_CFLAGS) -o framework-open/obj/properties.o framework-open/src/properties.cpp

framework-open/obj/risp.o: framework-open/src/risp.cpp $(FR_INC) $(RISP_INC)
	$(CXX) -c $(FR_CFLAGS) -o framework-open/obj/risp.o framework-open/src/risp.cpp

framework-open/obj/risp_static.o: framework-open/src/risp_static.cpp $(FR_INC) $(RISP_INC)
	$(CXX) -c $(FR_CFLAGS) -o framework-open/obj/risp_static.o framework-open/src/risp_static.cpp

framework-open/obj/vrisp.o: framework-open/src/vrisp.cpp $(FR_INC) $(VRISP_INC)
	$(CXX) -c $(FR_CFLAGS) -DNO_SIMD -o framework-open/obj/vrisp.o framework-open/src/vrisp.cpp

framework-open/obj/vrisp_rvv_full.o: framework-open/src/vrisp.cpp $(FR_INC) $(VRISP_INC)
	$(CXX) -c $(FR_CFLAGS) -DRISCVV_FULL -o framework-open/obj/vrisp_rvv_full.o framework-open/src/vrisp.cpp

framework-open/obj/vrisp_rvv_fired.o: framework-open/src/vrisp.cpp $(FR_INC) $(VRISP_INC)
	$(CXX) -c $(FR_CFLAGS) -DRISCVV_FIRED -o framework-open/obj/vrisp_rvv_fired.o framework-open/src/vrisp.cpp

framework-open/obj/vrisp_rvv_synapses.o: framework-open/src/vrisp.cpp $(FR_INC) $(VRISP_INC)
	$(CXX) -c $(FR_CFLAGS) -DRISCVV_SYNAPSES -o framework-open/obj/vrisp_rvv_synapses.o framework-open/src/vrisp.cpp

framework-open/obj/vrisp_static.o: framework-open/src/vrisp_static.cpp $(FR_INC) $(VRISP_INC)
	$(CXX) -c $(FR_CFLAGS) -o framework-open/obj/vrisp_static.o framework-open/src/vrisp_static.cpp

# Utility ######################################################################
dbscan/bin/dbscan_systolic_full:
	( cd $(DBSCAN_DIR) && make bin/dbscan_systolic_full )

framework-open/bin/network_tool:
	( cd $(FRAMEWORK_DIR) && make bin/network_tool )

# Clean up #####################################################################
clean: clean_dbscan clean_framework
	 rm -f bin/*

clean_dbscan:
	( cd dbscan/ ; make clean )

clean_framework:
	( cd framework-open/ ; make clean )

# clean_all: clean clean_dbscan clean_framework
# end
