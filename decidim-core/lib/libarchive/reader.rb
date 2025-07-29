# frozen_string_literal: true

module Libarchive
  class Reader
    attr_reader :archive

    def self.open_file(io, passphrase: nil)
      reader = new(passphrase: passphrase)
      reader.open(io)
      yield reader
    ensure
      reader.close
    end

    def initialize(passphrase: nil)
      @archive = Libarchive::CAPI.archive_read_new
      Libarchive::CAPI.archive_read_support_format_zip(archive)
      Libarchive::CAPI.archive_read_add_passphrase(archive, passphrase) if passphrase
    rescue Libarchive::Error
      close
      raise
    end

    def open(io)
      @buffer = nil

      read_callback = FFI::Function.new(:int, [:pointer, :pointer, :pointer]) do |_, _, archive_data|
        data = io.read(Libarchive::CAPI::DATA_BUFFER_SIZE) || ""
        @buffer = FFI::MemoryPointer.new(:char, data.size) if @buffer.nil? || @buffer.size < data.size
        @buffer.write_bytes(data)
        archive_data.write_pointer(@buffer)
        data.size
      end
      Libarchive::CAPI.archive_read_set_read_callback(archive, read_callback)

      Libarchive::CAPI.archive_read_set_callback_data(archive, nil)
      raise Libarchive::Error, archive unless Libarchive::CAPI.archive_read_open1(archive) == Libarchive::CAPI::OK
    end

    def close
      Libarchive::CAPI.archive_read_free(archive)
    end

    def entries
      entry_ptr = FFI::MemoryPointer.new(:pointer)
      while (centry = next_entry(entry_ptr))
        yield Entry.new(centry)
      end
    end

    def extract(entry, outdir)
      path = entry.path
      entry.path = "#{outdir}/#{path}"

      entry.extract_from(archive)
    ensure
      # Revert the pathname to the original
      entry.path = path
    end

    def extract_data(entry)
      return unless entry.file?

      if block_given?
        entry.data_from(archive) { |chunk| yield chunk }
      else
        data = nil
        entry.data_from(archive) do |chunk|
          data ||= "".dup
          data.concat(chunk)
        end

        data
      end
    end

    private

    def next_entry(entry_ptr)
      case Libarchive::CAPI.archive_read_next_header(archive, entry_ptr)
      when Libarchive::CAPI::OK
        entry_ptr.read_pointer
      when Libarchive::CAPI::EOF
        nil
      else
        raise Libarchive::Error, archive
      end
    end
  end
end
