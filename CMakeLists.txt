CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

#project name
PROJECT(coremark)

ADD_DEFINITIONS(-DFLAGS_STR="" -O2 -DPERFORMANCE_RUN=1 -DITERATIONS=0 -DPERFORMANCE_RUN=1)
LINK_DIRECTORIES(.)

ADD_EXECUTABLE(coremark core_list_join.c core_main.c core_matrix.c core_portme.c core_state.c core_util.c)
TARGET_LINK_LIBRARIES(coremark)

INSTALL(TARGETS coremark DESTINATION bin)
