#########
# ImGui #
#########

project(ImGui)

if (NOT RAZ_USE_GLEW)
    message(SEND_ERROR "Error: ImGui requires GLEW to be used.")
endif ()

set(CMAKE_CXX_STANDARD 17)

aux_source_directory(imgui IMGUI_SRC)

if (NOT RAZ_USE_GLFW)
    list(
        REMOVE_ITEM
        IMGUI_SRC

        imgui/imgui_impl_glfw.h
        imgui/imgui_impl_glfw.cpp
     )
endif ()

# Building ImGui
if (RAZ_BUILD_STATIC)
    add_library(ImGui STATIC ${IMGUI_SRC})
else ()
    add_library(ImGui SHARED ${IMGUI_SRC})
endif ()

target_include_directories(
    ImGui

    SYSTEM
    PUBLIC

    ${CMAKE_CURRENT_SOURCE_DIR}

    PRIVATE

    glew/include
)

# Disabling all compilers warnings
if (MSVC)
    target_compile_options(ImGui PRIVATE /w)
else ()
    target_compile_options(ImGui PRIVATE -w)
endif ()

target_link_libraries(ImGui GLEW)

if (RAZ_USE_GLFW)
    target_link_libraries(ImGui GLFW)
endif ()
