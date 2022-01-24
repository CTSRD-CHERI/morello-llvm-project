include(ExternalProject)

set(CHERI_COMPRESSED_CAP_UPSTREAM_PATH
  "${CMAKE_CURRENT_SOURCE_DIR}/cheri-compressed-cap-upstream")

ExternalProject_Add(cheri-compressed-cap-import-upstream
  EXCLUDE_FROM_ALL ON
  GIT_REPOSITORY https://github.com/CTSRD-CHERI/cheri-compressed-cap.git
  GIT_TAG 1ccdd5000420e8a2aa8b244f46dd386bd1870353
  GIT_SHALLOW OFF
  SOURCE_DIR "${CHERI_COMPRESSED_CAP_UPSTREAM_PATH}"
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_COMMAND ""
  )

add_library(cheri-compressed-cap-upstream INTERFACE IMPORTED GLOBAL)
add_dependencies(cheri-compressed-cap-upstream cheri-compressed-cap-import-upstream)
target_include_directories(cheri-compressed-cap-upstream
  INTERFACE "${CHERI_COMPRESSED_CAP_UPSTREAM_PATH}"
  )
