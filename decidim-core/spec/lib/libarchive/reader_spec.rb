# frozen_string_literal: true

require "spec_helper"
require "libarchive"

describe Libarchive::Reader do
  describe ".open_file" do
    let(:filepath) { File.expand_path("spec/assets/testarchive.zip") }
    let(:passphrase) { "foobar" }

    it "reads data from a password protected ZIP" do
      with_reader do |reader|
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

    it "allows reading data in chunks" do
      with_reader do |reader|
        idx = 0
        reader.entries do |entry|
          chunks = []
          reader.extract_data(entry) { |chunk| chunks.push(chunk) }

          case idx
          when 0
            expect(chunks).to eq(["Hello, world!"])
          when 1
            expect(chunks).to eq(["Foobar"])
          end

          idx += 1
        end
      end
    end

    context "when extracting" do
      let(:tmpdir) { Dir.mktmpdir("libarchive_spec") }

      it "extracts the data correctly" do
        with_reader do |reader|
          reader.entries do |entry|
            reader.extract(entry, tmpdir)
          end
        end

        expect(Dir.entries(tmpdir).excluding(".", "..")).to contain_exactly(
          "foobar.txt", "hello-world.txt"
        )

        expect(File.read("#{tmpdir}/hello-world.txt")).to eq("Hello, world!")
        expect(File.read("#{tmpdir}/foobar.txt")).to eq("Foobar")
      end
    end

    def with_reader
      File.open(filepath, "rb") do |file|
        Libarchive::Reader.open_file(file, passphrase: passphrase) do |reader|
          yield reader
        end
      end
    end
  end
end
