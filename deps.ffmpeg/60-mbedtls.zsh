autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='mbedtls'
local -A versions=(
  macos 2.26.0
  linux 2.26.0
  windows 2.24.0
)
local url='https://github.com/ARMmbed/mbedtls.git'
local -A hashes=(
  macos e483a77c85e1f9c1dd2eb1c5a8f552d2617fe400
  linux e483a77c85e1f9c1dd2eb1c5a8f552d2617fe400
  windows 523f0554b6cdc7ace5d360885c3f5bbcc73ec0e8
)
local -a patches=(
  "macos ${0:a:h}/patches/mbedtls/0001-enable-posix-threading-support.patch \
    363e6b8359f1c5fb8cc8e3c47439223c79de09935697e1d38c20336529fb9a5d"
  "linux ${0:a:h}/patches/mbedtls/0001-enable-posix-threading-support.patch \
    363e6b8359f1c5fb8cc8e3c47439223c79de09935697e1d38c20336529fb9a5d"
  "windows ${0:a:h}/patches/mbedtls/0001-enable-alt-threading-mode.patch \
    306b8aaee8f291cc0dbd4cbee12ea185e722469eb06b8b7113f0a60feca6bbe6"
  "windows ${0:a:h}/patches/mbedtls/0002-add-alt-threading-header-file.patch \
    d0dde0836dc6b100edf218207feffbbf808d04b1d0065082cdc5c838f8a4a7c7"
)

## Dependency Overrides
local -i shared_libs=1

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

  cd "${dir}"

  local patch
  local _target
  local _url
  local _hash
  for patch (${patches}) {
    read _target _url _hash <<< "${patch}"

    if [[ ${_target} == "${target%%-*}" ]] apply_patch "${_url}" "${_hash}"
  }
}

config() {
  autoload -Uz mkcd progress

  local _onoff=(OFF ON)

  args=(
    ${cmake_flags}
    -DUSE_SHARED_MBEDTLS_LIBRARY="${_onoff[(( shared_libs + 1 ))]}"
    -DUSE_STATIC_MBEDTLS_LIBRARY=ON
    -DENABLE_PROGRAMS=OFF
    -DENABLE_TESTING=OFF
    -DGEN_FILES=OFF
  )

  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"
  log_debug "CMake configuration options: ${args}'"
  progress cmake -S . -B "build_${arch}" -G Ninja ${args}
}

build() {
  autoload -Uz mkcd progress

  log_info "Build (%F{3}${target}%f)"

  cd "${dir}"

  args=(
    --build "build_${arch}"
    --config "${config}"
  )

  if (( _loglevel > 1 )) args+=(--verbose)

  cmake ${args}
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  args=(
    --install "build_${arch}"
    --config "${config}"
  )

  if [[ "${config}" =~ "Release|MinSizeRel" ]] args+=(--strip)
  if (( _loglevel > 1 )) args+=(--verbose)

  cd "${dir}"
  progress cmake ${args}

  _install_pkgconfig
}


_install_pkgconfig() {
  mkdir -p "${target_config[output_dir]}/lib/pkgconfig"

  zsh -c "cat <<'EOF' > ${target_config[output_dir]}/lib/pkgconfig/mbedcrypto.pc
prefix=${target_config[output_dir]}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedcrypto
Description: lightweight crypto and SSL/TLS library.
Version: ${version:-${versions[${target%%-*}]}}
Libs: -L\${libdir} -lmbedcrypto
Cflags: -I\${includedir}
EOF"

  zsh -c "cat <<'EOF' > ${target_config[output_dir]}/lib/pkgconfig/mbedtls.pc
prefix=${target_config[output_dir]}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedtls
Description: lightweight crypto and SSL/TLS library.
Version: ${version:-${versions[${target%%-*}]}}
Libs: -L\${libdir} -lmbedtls
Cflags: -I\${includedir}
Requires.private: mbedx509
EOF"

  zsh -c "cat <<'EOF' > ${target_config[output_dir]}/lib/pkgconfig/mbedx509.pc
prefix=${target_config[output_dir]}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mbedx509
Description: The mbedTLS X.509 library
Version: ${version:-${versions[${target%%-*}]}}
Libs: -L\${libdir} -lmbedx509
Cflags: -I\${includedir}
Requires.private: mbedcrypto
EOF"
}

fixup() {
  cd "${dir}"

  if [[ ${target} == "windows-x"* ]] {
    log_info "Fixup (%F{3}${target}%f)"
    if (( shared_libs )) {
      mkdir -p ${target_config[output_dir]}/bin
      autoload -Uz create_importlibs
      create_importlibs ${target_config[output_dir]}/lib/libmbed*.dll

      for file ("${target_config[output_dir]}"/lib/libmbed*.dll(.)) {
        mv ${file} "${target_config[output_dir]}/bin/${file##*/}"

        log_status "Moved ${file#${target_config[output_dir]}} to /bin/${file##*/}"
      }
    }
  }
}
