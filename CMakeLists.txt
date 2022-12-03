cmake_minimum_required(VERSION 3.21...3.23)

# LLVM requires CMP0116 for tblgen: https://reviews.llvm.org/D101083
# CMP0116: Ninja generators transform `DEPFILE`s from `add_custom_command()`
# New in CMake 3.20. https://cmake.org/cmake/help/latest/policy/CMP0116.html
set(CMAKE_POLICY_DEFAULT_CMP0116 OLD)

# Output compile_commands.json by default for better IDE support.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(my-riscv-llvm-sandbox ASM C CXX)
set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 17)

# LLVM defines this as a CACHE property and uses a policy that causes the
# cache value to take precedence. This is causing us to mix 17/14 across
# the boundary.
# TODO: Remove this once the LLVM mechanism is updated. See:
#   https://discourse.llvm.org/t/important-new-toolchain-requirements-to-build-llvm-will-most-likely-be-landing-within-a-week-prepare-your-buildbots/61447/9
set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to conform to" FORCE)

# Set the default CMake build type so some of the build type dependent setting
set(DEFAULT_CMAKE_BUILD_TYPE "Release")

#-------------------------------------------------------------------------------
# Project component configuration
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Project cmake utilities
#-------------------------------------------------------------------------------

set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)

#-------------------------------------------------------------------------------
# Other dependencies
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Project source
#-------------------------------------------------------------------------------

add_subdirectory(cpp)
