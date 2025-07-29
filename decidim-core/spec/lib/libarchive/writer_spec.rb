# frozen_string_literal: true

require "spec_helper"
require "libarchive"

describe Libarchive::Writer do
  describe ".open" do
    let(:tempfile) { Tempfile.new("archive.zip") }
    let(:passphrase) { "foobar" }
    let(:filetime) { Time.zone.local(2025, 7, 29, 12, 0, 0) }

    let(:expected_contents) do
      data = nil
      File.open("spec/assets/testarchive.zip", "rb") do |file|
        file.set_encoding(Encoding::ASCII_8BIT)
        data = file.read
      end
      data
    end

    before do
      allow(Time).to receive(:current).and_return(filetime)
    end

    after do
      tempfile.close
      tempfile.unlink
    end

    it "creates a correct zip archive" do
      described_class.open(tempfile, passphrase: passphrase) do |writer|
        writer.add_data("Hello, world!", "hello-world.txt")
        writer.add_data("Foobar", "foobar.txt")
      end

      tempfile.rewind

      Libarchive::Reader.open_file(tempfile, passphrase: passphrase) do |reader|
        idx = 0
        reader.entries do |entry|
          case idx
          when 0
            expect(entry.path).to eq("hello-world.txt")
            expect(reader.extract_data(entry)).to eq("Hello, world!")
          when 1
            expect(entry.path).to eq("foobar.txt")
            expect(reader.extract_data(entry)).to eq("Foobar")
          end

          idx += 1
        end
      end
    end
  end
end
