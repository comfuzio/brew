# typed: strict
# frozen_string_literal: true

require "version"

# Helper functions for querying operating system information.
module OS
  # Check whether the operating system is macOS.
  #
  # @api public
  sig { returns(T::Boolean) }
  def self.mac?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]

    RbConfig::CONFIG["host_os"].include? "darwin"
  end

  # Check whether the operating system is Linux.
  #
  # @api public
  sig { returns(T::Boolean) }
  def self.linux?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]

    RbConfig::CONFIG["host_os"].include? "linux"
  end

  # Get the kernel version.
  #
  # @api public
  sig { returns(Version) }
  def self.kernel_version
    require "etc"
    @kernel_version ||= T.let(Version.new(Etc.uname.fetch(:release)), T.nilable(Version))
  end

  # Get the kernel name.
  #
  # @api public
  sig { returns(String) }
  def self.kernel_name
    require "etc"
    @kernel_name ||= T.let(Etc.uname.fetch(:sysname), T.nilable(String))
  end

  ::OS_VERSION = T.let(ENV.fetch("HOMEBREW_OS_VERSION").freeze, String)

  # See Linux-CI.md
  LINUX_CI_OS_VERSION = "Ubuntu 22.04"
  LINUX_GLIBC_CI_VERSION = "2.35"
  LINUX_GLIBC_NEXT_CI_VERSION = "2.39"
  LINUX_GCC_CI_VERSION = "11.0"
  LINUX_PREFERRED_GCC_COMPILER_FORMULA = "gcc@11" # https://packages.ubuntu.com/jammy/gcc
  LINUX_PREFERRED_GCC_RUNTIME_FORMULA = "gcc"

  if OS.mac?
    require "os/mac"
    require "hardware"
    # Don't tell people to report issues on non-Tier 1 configurations.
    if !OS::Mac.version.prerelease? &&
       !OS::Mac.version.outdated_release? &&
       ARGV.none? { |v| v.start_with?("--cc=") } &&
       (HOMEBREW_PREFIX.to_s == HOMEBREW_DEFAULT_PREFIX ||
       (HOMEBREW_PREFIX.to_s == HOMEBREW_MACOS_ARM_DEFAULT_PREFIX && Hardware::CPU.arm?))
      ISSUES_URL = "https://docs.brew.sh/Troubleshooting"
    end
    PATH_OPEN = "/usr/bin/open"
  elsif OS.linux?
    require "os/linux"
    ISSUES_URL = "https://docs.brew.sh/Troubleshooting"
    PATH_OPEN = if OS::Linux.wsl? && (wslview = which("wslview").presence)
      wslview.to_s
    else
      "xdg-open"
    end.freeze
  end

  sig { returns(T::Boolean) }
  def self.not_tier_one_configuration?
    !defined?(OS::ISSUES_URL)
  end
end
