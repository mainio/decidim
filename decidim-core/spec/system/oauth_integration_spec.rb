# frozen_string_literal: true

require "spec_helper"

describe "Authorzing with OAUth applications", type: :system do
  let(:user) { create(:user, :confirmed) }
  let(:organization) { user.organization }
  let(:application) { create(:oauth_application, organization: organization) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim.oauth_authorization_url(host: application.owner.host, client_id: application.uid, redirect_uri: application.redirect_uri, response_type: "code")
    expect(page).to have_content("wants to use your account")
  end

  describe "authorization screen" do
    it "displays information about the app" do
      within "div.wrapper" do
        expect(page).to have_content(application.name)
        expect(page).to have_link(application.organization_name, href: application.organization_url)
      end
    end
  end

  describe "authorize the application" do
    it "redirects to the redirect uri with a code" do
      click_button "Authorize application"
      expect(page).to have_content("DNS_PROBE_FINISHED_NXDOMAIN")

      expect(current_url).to start_with("#{application.redirect_uri}?code=")
    end
  end

  describe "cancel the request" do
    it "redirects to the redirect uri with an error" do
      click_button "Cancel"
      expect(page).to have_content("DNS_PROBE_FINISHED_NXDOMAIN")

      expect(current_url).to start_with("#{application.redirect_uri}?error=access_denied&error_description=")
    end
  end
end
