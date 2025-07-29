# frozen_string_literal: true

module Libarchive
  class Entry
    # https://github.com/libarchive/libarchive/blob/6062470cbcf5ff76535b6f161ce9cc9f4c6f56c0/libarchive/archive_entry.h#L215-L222
    S_IFMT = 0o170000
    S_IFREG = 0o100000
    S_IFLNK = 0o120000
    S_IFDIR = 0o040000

    def initialize(centry)
      @centry = centry
    end

    def free
      Libarchive::CAPI.archive_entry_free(centry)
    end

    def filetype
      Libarchive::CAPI.archive_entry_filetype(centry)
    end

    def file?
      filetype & S_IFMT == S_IFREG
    end

    def directory?
      filetype & S_IFMT == S_IFDIR
    end

    def path
      Libarchive::CAPI.archive_entry_pathname(centry)
    end

    def path=(pathname)
      Libarchive::CAPI.archive_entry_set_pathname(centry, pathname)
    end

    def extract_from(archive)
      flags = Libarchive::EXTRACT_FFLAGS
      raise Libarchive::Error, archive unless Libarchive::CAPI.archive_read_extract(archive, centry, flags) == Libarchive::CAPI::OK
    end

    def data_from(archive)
      size = Libarchive::CAPI::DATA_BUFFER_SIZE
      buffer = FFI::MemoryPointer.new(size)
      while (chunk = read_next(archive, buffer, size))
        yield chunk
      end
    end

    private

    attr_reader :centry

    def read_next(archive, buffer, size)
      result = Libarchive::CAPI.archive_read_data(archive, buffer, size)
      return unless result.positive?

      case result
      when Libarchive::CAPI::FATAL, Libarchive::CAPI::WARN, Libarchive::CAPI::RETRY
        raise Libarchive::Error, archive
      else
        buffer.get_bytes(0, result)
      end
    end
  end
end
