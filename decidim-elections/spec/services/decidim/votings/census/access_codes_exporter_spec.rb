# frozen_string_literal: true

require "spec_helper"
require "libarchive"

module Decidim
  module Votings
    module Census
      describe AccessCodesExporter do
        subject { AccessCodesExporter.new(dataset, tmp_file_in.path, password) }

        let(:tmp_file_in) { Tempfile.new(["access_codes", ".zip"]) }
        let(:tmp_dir_out) { Dir.mktmpdir("access_codes_exporter_spec") }
        let(:dataset) { create(:dataset, :with_access_code_data) }
        let(:password) { "secret" }
        let(:user) { create :user }
        let(:expected_file) { "#{translated(dataset.voting.title).parameterize}-voting-access-codes.csv" }

        describe "#export" do
          it "compresses a password protected file" do
            subject.export

            files, data = open_and_extract_zip(tmp_file_in.path)

            expect(files).to contain_exactly(expected_file)
            dataset.data.each do |datum|
              expect(data).to include(datum.full_name)
              expect(data).to include(datum.full_address)
              expect(data).to include(datum.postal_code)
              expect(data).to include(datum.access_code)
            end
          end
        end

        private

        def open_and_extract_zip(file_path)
          files = []
          data = "".dup
          File.open(file_path, "rb") do |file|
            Libarchive::Reader.open_file(file, passphrase: password) do |reader|
              reader.entries do |entry|
                files.push(entry.path)
                data.concat(reader.extract_data(entry))
              end
            end
          end

          [files, data]
        end
      end
    end
  end
end
