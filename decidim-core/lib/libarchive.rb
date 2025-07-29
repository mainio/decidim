# frozen_string_literal: true

# The Libarchive module provides a replacement for the `seven_zip_ruby`
# gem that supports a similar API as the `seven_zip_ruby` used to provide.
# However, there are few differences compared to the old implementation.
#
# The most significant difference is that this module produces AES-256 encrypted
# ZIP files with the deflate compression method that should be compatible with
# more ZIP programs than the files generated through `seven_zip_ruby`.
# SevenZipRuby uses the LZMA compression by default which is not supported by
# all ZIP programs.
#
# Another difference is that Libarchive does not support encrypting the ZIP
# headers which means that the headers (i.e. the ZIP metadata and the file names
# contained within the archive) are stored in plain text. Given the use case,
# this is not a problem because the encrypted ZIP contains only another ZIP file
# that contains the actual information. Therefore, having that file name shown
# in plain text should not be a problem.
#
# The final difference is in the way how the files are extracted. SevenZipRuby
# allowed either extracting or reading all data files in a single call but this
# library requires processing each file individually.
#
# This binds the C-API from the `libarchive` library to Ruby using FFI. The FFI
# gem is already a Decidim core dependency through the following dependency
# paths:
#   spring-watcher-listen -> listen -> rb-inotify
#   decidim-api -> graphql-docs -> sass -> sass-listen -> rb-inotify
#   decidim-core -> carrierwave -> image_processing -> ruby-vips
module Libarchive
  FORMAT_ZIP = 0x50000
  EXTRACT_FFLAGS = 0x0040

  autoload :CAPI, "libarchive/capi"
  autoload :Entry, "libarchive/entry"
  autoload :Reader, "libarchive/reader"
  autoload :Writer, "libarchive/writer"

  class Error < StandardError
    def initialize(archive)
      if archive.is_a?(String)
        super archive
      else
        super Libarchive::CAPI.archive_error_string(archive).to_s
      end
    end
  end
end
