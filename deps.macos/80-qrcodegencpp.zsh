autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='qrcodegencpp'
local version='1.8.0'
local url='https://github.com/nayuki/QR-Code-generator.git'
local hash='720f62bddb7226106071d4728c292cb1df519ceb'
local url_cmake='https://github.com/EasyCoding/qrcodegen-cmake.git'
local hash_cmake='c57623d48a2d422b0f908dcf22d56d603e56c0e4'

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}

  mkcd ../"qrcodegen-cmake-${version}"
  dep_checkout ${url_cmake} ${hash_cmake}
}

clean() {
  cd "${dir}"

  if [[ ${clean_build} -gt 0 && -d "build_${arch}" ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf "build_${arch}"
  }
}

patch() {
  autoload -Uz apply_patch

  log_info "Patch (%F{3}${target}%f)"
  cp -R "qrcodegen-cmake-${version}"/(cmake|CMakeLists.txt) "${dir}"
}

config() {
  autoload -Uz mkcd progress

  log_info "Config (%F{3}${target}%f)"

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DBUILD_SHARED_LIBS="${_onoff[(( shared_libs + 1 ))]}"
  )

  cd "${dir}"
  log_debug "CMake configure options: ${args}"
  progress cmake -S . -B "build_${arch}" -G Ninja ${args}
}

build() {
  autoload -Uz mkcd

  log_info "Build (%F{3}${target}%f)"

  cd "${dir}"
  cmake --build "build_${arch}" --config "${config}"
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  args=(
    --install "build_${arch}"
    --config "${config}"
  )

  if [[ "${config}" =~ "Release|MinSizeRel" ]] args+=(--strip)

  cd "${dir}"
  progress cmake ${args}
}

fixup() {
  cd "${dir}"

  log_info "Fixup (%F{3}${target}%f)"

  rm -rf "${target_config[output_dir]}"/include/qrcodegen
  rm -rf "${target_config[output_dir]}"/lib/cmake/qrcodegen
  rm -rf "${target_config[output_dir]}"/lib/pkgconfig/qrcodegen.pc
  rm -rf "${target_config[output_dir]}"/lib/libqrcodegen.*

  case ${target} {
    macos*)
      if (( shared_libs )) {
        autoload -Uz fix_rpaths
        fix_rpaths "${target_config[output_dir]}"/lib/libqrcodegencpp*.dylib

        for file ("${target_config[output_dir]}"/lib/cmake/qrcodegencpp/qrcodegencpp-targets-*.cmake) {
          sed -i '' 's/libqrcodegencpp.*.dylib/libqrcodegencpp.dylib/' "${file}"
        }
      }
      ;;
  }
}
