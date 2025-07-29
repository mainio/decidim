# frozen_string_literal: true

require "ffi" unless defined?(FFI)

module Libarchive
  module CAPI
    extend FFI::Library
    if RUBY_PLATFORM.match?(/mswin|mingw|windows/)
      ffi_lib %w(libarchive archive)
    else
      ffi_lib %w(libarchive.so.13 libarchive.13 libarchive-13 libarchive.so libarchive archive)
    end

    callback :archive_write_callback, [:pointer, :pointer, :pointer, :size_t], :int
    callback :archive_read_callback, [:pointer, :pointer, :pointer], :int

    attach_function :archive_error_string, [:pointer], :string

    attach_function :archive_write_new, [], :pointer
    attach_function :archive_write_finish, [:pointer], :void
    attach_function :archive_write_set_format, [:pointer, :int], :int
    attach_function :archive_write_set_options, [:pointer, :string], :int
    attach_function :archive_write_set_passphrase, [:pointer, :string], :int
    attach_function :archive_write_open, [:pointer, :pointer, :pointer, :archive_write_callback, :pointer], :int
    # attach_function :archive_write_open_filename, [:pointer, :string], :int

    attach_function :archive_entry_new, [], :pointer
    attach_function :archive_entry_free, [:pointer], :void
    attach_function :archive_entry_set_mode, [:pointer, :mode_t], :void
    attach_function :archive_entry_set_pathname, [:pointer, :string], :void
    attach_function :archive_entry_set_atime, [:pointer, :time_t, :long], :int
    attach_function :archive_entry_set_mtime, [:pointer, :time_t, :long], :int
    attach_function :archive_entry_set_ctime, [:pointer, :time_t, :long], :int

    attach_function :archive_write_header, [:pointer, :pointer], :int
    attach_function :archive_write_data, [:pointer, :pointer, :size_t], :ssize_t

    attach_function :archive_read_new, [], :pointer
    attach_function :archive_read_support_format_zip, [:pointer], :int
    attach_function :archive_read_support_format_7zip, [:pointer], :int
    attach_function :archive_read_add_passphrase, [:pointer, :string], :pointer
    attach_function :archive_read_set_read_callback, [:pointer, :archive_read_callback], :int
    attach_function :archive_read_set_callback_data, [:pointer, :pointer], :int
    attach_function :archive_read_open1, [:pointer], :int
    attach_function :archive_read_next_header, [:pointer, :pointer], :int

    attach_function :archive_entry_filetype, [:pointer], :mode_t
    attach_function :archive_entry_mode, [:pointer], :mode_t
    attach_function :archive_entry_pathname, [:pointer], :string
    attach_function :archive_read_extract, [:pointer, :pointer, :int], :int
    attach_function :archive_read_data, [:pointer, :pointer, :size_t], :ssize_t
    attach_function :archive_read_close, [:pointer], :int
    attach_function :archive_read_free, [:pointer], :int

    EOF = 1
    OK = 0
    RETRY = -10
    WARN = -20
    FAILED = -25
    FATAL = -30

    DATA_BUFFER_SIZE = 2**16
  end
end
