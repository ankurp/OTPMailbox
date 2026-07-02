require "application_system_test_case"

class HomesTest < ApplicationSystemTestCase
  test "visiting the homepage" do
    visit root_url

    assert_selector "h1", text: "OTP Mailbox"
  end
end
