autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='ads'
local version='4.2.1'
local url='https://github.com/githubuser0xFFFF/Qt-Advanced-Docking-System.git'
local hash="ec018a4c7063b3f9d7a24f32d73b1428c450851e"

## Dependency Overrides
local -i shared_libs=0

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd "${dir}"

  if [[ ${clean_build} -gt 0 && -d "build_${arch}" ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf "build_${arch}"
  }
}

config() {
  autoload -Uz mkcd progress

  log_info "Config (%F{3}${target}%f)"

  local _offon=(ON OFF)

  args=(
    ${cmake_flags}
    -DBUILD_STATIC="${_offon[(( shared_libs + 1 ))]}"
    -DBUILD_EXAMPLES=OFF
  )

  if [[ ${CPUTYPE} != ${arch} && ${host_os} == macos ]] {
    unset VCPKG_ROOT
    if ! /usr/bin/pgrep -q oahd; then
      local -A other_arch=(arm64 x86_64 x86_64 arm64)
      args+=(-DCMAKE_OSX_ARCHITECTURES:STRING="${CPUTYPE};${other_arch[${CPUTYPE}]}")
    fi
  }

  cd "${dir}"
  log_debug "CMake configure options: ${args}'"
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
  cd ${dir}

  log_info "Fixup (%F{3}${target}%f)"

  if ((shared_libs)) {
    local -a dylib_files=(${target_config[output_dir]}/lib/libqt6advanceddocking*.dylib(.))
        
    autoload -Uz fix_rpaths
    fix_rpaths ${dylib_files}

    if [[ ${config} == (Release|MinSizeRel) ]] {
      dsymutil ${dylib_files}
      strip -x ${dylib_files}
    }

    for file (${target_config[output_dir]}/lib/cmake/qt6advanceddocking/adsTargets-*.cmake) {
      sed -i '' 's/libqt6advanceddocking.*.dylib/libqt6advanceddocking.dylib/' "${file}"
    }
  }
}
