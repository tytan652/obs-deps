autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='asio'
local version='1.20.0'
local url='https://github.com/chriskohlhoff/asio.git'
local hash='b73dc1d2c0ecb9452a87c26544d7f71e24342df6'

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd "${dir}/asio"

  if [[ ${clean_build} -gt 0 && -f "build_${arch}/Makefile" ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf "build_${arch}"
  }
}

config() {
  autoload -Uz mkcd progress

  log_info "Config (%F{3}${target}%f)"

  cd "${dir}/asio"

  progress ./autogen.sh

  mkcd "build_${arch}"

  args+=(
    --without-boost
    --without-openssl
    --prefix="${target_config[output_dir]}"
  )

  log_debug "Configure options: ${args}"
  progress ../configure ${args}
}

build() {
  autoload -Uz mkcd progress

  log_info "Build (%F{3}${target}%f)"
  cd "${dir}/asio/build_${arch}"

  log_debug "Running make -j ${num_procs}"
  PATH="${(j.:.)cc_path}" progress make -j "${num_procs}"
}

install() {
  autoload -Uz progress

  if [[ ! -d "${dir}/asio/build_${arch}" ]] {
    log_warning "No headers found, skipping installation"
    return
  }

  log_info "Install (%F{3}${target}%f)"
  cd "${dir}/asio/build_${arch}"

  progress make install
}
