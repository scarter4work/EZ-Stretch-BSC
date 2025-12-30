cmake_minimum_required(VERSION 3.16)
project(BayesianAstro VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# PixInsight SDK path (set via environment or command line)
if(NOT DEFINED PIXINSIGHT_SDK)
    set(PIXINSIGHT_SDK $ENV{PIXINSIGHT_SDK})
endif()

if(NOT PIXINSIGHT_SDK)
    message(FATAL_ERROR "PIXINSIGHT_SDK not set. Set environment variable or pass -DPIXINSIGHT_SDK=<path>")
endif()

# Julia path
find_package(Julia QUIET)
if(NOT Julia_FOUND)
    # Manual Julia detection
    if(NOT DEFINED JULIA_DIR)
        set(JULIA_DIR $ENV{JULIA_DIR})
    endif()

    if(JULIA_DIR)
        set(Julia_INCLUDE_DIRS "${JULIA_DIR}/include/julia")
        set(Julia_LIBRARY "${JULIA_DIR}/lib/libjulia.so")
        if(WIN32)
            set(Julia_LIBRARY "${JULIA_DIR}/bin/libjulia.dll")
        endif()
    endif()
endif()

# Qt6 for WebEngine (embedded React UI)
find_package(Qt6 REQUIRED COMPONENTS Core Widgets WebEngineWidgets WebChannel)

# PixInsight Class Library
set(PCL_INCLUDE_DIR "${PIXINSIGHT_SDK}/include")
set(PCL_LIBRARY_DIR "${PIXINSIGHT_SDK}/lib")

# Source files
set(SOURCES
    src/BayesianAstroModule.cpp
    src/BayesianAstroProcess.cpp
    src/BayesianAstroInstance.cpp
    src/BayesianAstroInterface.cpp
    src/BayesianAstroParameters.cpp
    src/JuliaRuntime.cpp
)

set(HEADERS
    include/BayesianAstroModule.h
    include/BayesianAstroProcess.h
    include/BayesianAstroInstance.h
    include/BayesianAstroInterface.h
    include/BayesianAstroParameters.h
    include/JuliaRuntime.h
)

# Build shared library (PixInsight module)
add_library(BayesianAstro SHARED ${SOURCES} ${HEADERS})

target_include_directories(BayesianAstro PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${PCL_INCLUDE_DIR}
    ${Julia_INCLUDE_DIRS}
)

target_link_directories(BayesianAstro PRIVATE
    ${PCL_LIBRARY_DIR}
)

target_link_libraries(BayesianAstro PRIVATE
    PCL-pxi
    Qt6::Core
    Qt6::Widgets
    Qt6::WebEngineWidgets
    Qt6::WebChannel
    ${Julia_LIBRARY}
)

# Platform-specific settings
if(WIN32)
    set_target_properties(BayesianAstro PROPERTIES
        SUFFIX ".dll"
        PREFIX ""
    )
elseif(APPLE)
    set_target_properties(BayesianAstro PROPERTIES
        SUFFIX ".dylib"
        PREFIX ""
    )
else()
    set_target_properties(BayesianAstro PROPERTIES
        SUFFIX ".so"
        PREFIX ""
    )
endif()

# Install rules
install(TARGETS BayesianAstro
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

# Copy React UI assets
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../ui/dist/
    DESTINATION share/BayesianAstro/ui
)
