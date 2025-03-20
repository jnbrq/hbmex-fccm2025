
if (FALSE)
generate_tb(
    TARGET_NAME Memories
    HDL_MODULES
        Memories_Basic1
        Memories_Basic2
        Memories_LongLatency1
        Memories_LongLatency2
        Memories_Interleaved
)

generate_tb(
    TARGET_NAME AxiBridges
    HDL_MODULES
        AxiBridges_Axi4Full1
        AxiBridges_Axi4Lite1
)

endif()