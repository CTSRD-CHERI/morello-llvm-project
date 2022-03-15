add_lldb_unittest(LLDBPlatformTests
  PlatformAppleSimulatorTest.cpp
  PlatformDarwinTest.cpp
  PlatformMacOSXTest.cpp
  PlatformSiginfoTest.cpp

  LINK_LIBS
    lldbPluginPlatformFreeBSD
    lldbPluginPlatformLinux
    lldbPluginPlatformMacOSX
    lldbPluginPlatformNetBSD
  LINK_COMPONENTS
    Support
    RuntimeDyld
  )

add_subdirectory(Android)
