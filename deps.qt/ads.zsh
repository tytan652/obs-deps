autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='ads'
local version='3.8.3'
local url='https://github.com/githubuser0xFFFF/Qt-Advanced-Docking-System.git'
local hash="89ff0ad311ec0cba7e7685c070d3be3a055cce71"
local -a patches=()
local -a qt5_patches=(
  "macos ${0:a:h}/patches/ADS/macos/0001-use-qt-build-executable.patch \
    1497f970c1486f5da8b6744dc7f581b9b96ba79308f8cc8bfc52cce09c471bb7"
)

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

patch() {
  autoload -Uz apply_patch

  log_info "Patch (%F{3}${target}%f)"

  cd ${dir}

  local patch
  local _target
  local _url
  local _hash

  if [[ ${PACKAGE_NAME} == 'qt5' ]] {
    for patch (${qt5_patches}) {
      read _target _url _hash <<< "${patch}"

      if [[ "${target%%-*}" == ${~_target} ]] apply_patch "${_url}" "${_hash}"
    }
  }

  for patch (${patches}) {
    read _target _url _hash <<< "${patch}"

    if [[ "${target%%-*}" == ${~_target} ]] apply_patch "${_url}" "${_hash}"
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

  if [[ ${PACKAGE_NAME} == 'qt5' ]] {
    args+=(-DQT_BIN_DIR="${work_root}/${PACKAGE_NAME}/qtbase/build_${arch}/bin")
  }

  if [[ ${CPUTYPE} != "${arch}" && ${host_os} == 'macos' && ${PACKAGE_NAME} == 'qt6' ]] {
    if ! /usr/bin/pgrep -q oahd; then
      local -A other_arch=(arm64 x86_64 x86_64 arm64)
      args+=(-DCMAKE_OSX_ARCHITECTURES="${CPUTYPE};${other_arch[${CPUTYPE}]}")
    fi
  }

  cd "${dir}"
  log_debug "CMake configure args: ${args}'"
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
