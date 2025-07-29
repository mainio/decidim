# frozen_string_literal: true

module Libarchive
  class Writer
    attr_reader :archive

    def self.open(io, passphrase: nil)
      io.set_encoding(Encoding::ASCII_8BIT)

      writer = new(passphrase: passphrase)
      begin
        writer.open(io)
        yield writer
      ensure
        writer.close
      end
    end

    def initialize(passphrase: nil)
      @archive = Libarchive::CAPI.archive_write_new
      @write_open = false

      raise Libarchive::Error, archive if Libarchive::CAPI.archive_write_set_format(archive, Libarchive::FORMAT_ZIP) != Libarchive::CAPI::OK

      if passphrase
        raise Libarchive::Error, archive if Libarchive::CAPI.archive_write_set_options(archive, "encryption=aes256") != Libarchive::CAPI::OK
        raise Libarchive::Error, archive if Libarchive::CAPI.archive_write_set_passphrase(archive, passphrase) != Libarchive::CAPI::OK
      end
    rescue Libarchive::Error
      close
      raise
    end

    def open(io)
      raise Libarchive::Error, "This writer has been already closed." unless archive

      write_callback = proc do |_ar, _client, buffer, length|
        io.write(buffer.get_bytes(0, length))
        length
      end
      raise Libarchive::Error, archive if Libarchive::CAPI.archive_write_open(archive, nil, nil, write_callback, nil) != Libarchive::CAPI::OK

      @write_open = true
    end

    def close
      Libarchive::CAPI.archive_write_finish(archive)
      @write_open = false
      @archive = nil
    end

    def add_data(data, pathname, atime: nil, mtime: nil, ctime: nil)
      raise Libarchive::Error, "You must add the files through the write_entries method." unless write_open

      entry = Libarchive::CAPI.archive_entry_new

      time = Time.current
      atime ||= time
      mtime ||= time
      ctime ||= time
      Libarchive::CAPI.archive_entry_set_atime(entry, atime.to_i, 0)
      Libarchive::CAPI.archive_entry_set_mtime(entry, mtime.to_i, 0)
      Libarchive::CAPI.archive_entry_set_ctime(entry, ctime.to_i, 0)

      Libarchive::CAPI.archive_entry_set_mode(entry, Libarchive::Entry::S_IFREG | 0o444)
      Libarchive::CAPI.archive_entry_set_pathname(entry, pathname)

      Libarchive::CAPI.archive_write_header(archive, entry)
      Libarchive::CAPI.archive_write_data(archive, data, data.bytesize)

      Libarchive::CAPI.archive_entry_free(entry)
    end

    private

    attr_reader :write_open
  end
end
