# frozen_string_literal: true

require "spec_helper"

describe Decidim::Abilities::ParticipatoryProcessCollaboratorAbility do
  let!(:user) do
    create(:user, :process_collaborator, participatory_process: user_process)
  end

  let(:user_process) { create :participatory_process }

  let(:published_feature) do
    create(:feature, participatory_process: user_process)
  end

  let(:unpublished_feature) do
    create(:feature, participatory_process: user_process)
  end

  subject { described_class.new(user, current_participatory_process: user_process) }

  it { is_expected.to be_able_to(:read, user_process) }
  it { is_expected.to be_able_to(:read, published_feature) }
  it { is_expected.to be_able_to(:read, unpublished_feature) }
end
