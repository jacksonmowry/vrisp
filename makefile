# vrisp
#
# @file
# @version 0.1

CXX ?= g++

FR_LIB = framework-open/lib/libframework.a
FR_INCLUDES = framework-open/include/

RISP_OBJ = framework-open/obj/risp.o framework-open/obj/risp_static.o
VRISP_OBJ = framework-open/obj/vrisp.o  framework-open/obj/vrisp_static.o

FRAMEWORK_DIR = framework-open/
DBSCAN_DIR = dbscan/

all: bin/dbscan_app_risp \
	 bin/dbscan_app_vrisp \
	 bin/downscale_app_risp \
	 bin/downscale_app_vrisp

bin/dbscan_app_risp: src/dbscan_app.cpp framework
	$(CXX) $(CFLAGS) -o bin/dbscan_app_risp src/dbscan_app.cpp $(RISP_OBJ) $(FR_LIB) -I$(FR_INCLUDES)

bin/dbscan_app_vrisp: src/dbscan_app.cpp framework
	$(CXX) $(CFLAGS) -o bin/dbscan_app_vrisp src/dbscan_app.cpp $(VRISP_OBJ) $(FR_LIB) -I$(FR_INCLUDES)

bin/downscale_app_risp: src/downscale_app.cpp framework
	$(CXX) $(CFLAGS) -o bin/downscale_app_risp src/downscale_app.cpp $(RISP_OBJ) $(FR_LIB) -I$(FR_INCLUDES)

bin/downscale_app_vrisp: src/downscale_app.cpp framework
	$(CXX) $(CFLAGS) -o bin/downscale_app_vrisp src/downscale_app.cpp $(VRISP_OBJ) $(FR_LIB) -I$(FR_INCLUDES)

dbscan:
	( cd $(DBSCAN_DIR); make )

framework:
	( cd $(FRAMEWORK_DIR); make )

clean:
	 rm -f bin/*

clean_dbscan:
	( cd dbscan/ ; make clean )

clean_framework:
	( cd framework-open/ ; make clean )

clean_all: clean clean_dbscan clean_framework

# end
